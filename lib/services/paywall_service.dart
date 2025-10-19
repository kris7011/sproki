import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of a purchase attempt
class PurchaseResult {
  final bool success;
  final String? message;
  const PurchaseResult({required this.success, this.message});
}

class PaywallService {
  // ---- Public constants ----
  static const productId = 'sproki_premium_lifetime'; // DIT IAP produkt-id
  static const int freeAttemptsPerChild = 7;
  static const _packageNameAndroid = 'com.sproki.sproki'; // DIT package name

  // ---- Storage keys ----
  static const _prefsKeyPremium = 'premium_v1';
  static String _attemptKey(String childId) => 'attempts_${childId}_v1';

  const PaywallService();
  static const PaywallService instance = PaywallService();

  // ---------------- Premium flag (lokal cache)
  Future<bool> isPremium() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefsKeyPremium) ?? false;
  }

  Future<void> _setPremiumLocally(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefsKeyPremium, v);
  }

  // ---------------- Free-tier gating (lokalt pr. barn)
  Future<bool> isLockedForChildAsync(String childId) async {
    if (await isPremium()) return false;
    final p = await SharedPreferences.getInstance();
    final used = p.getInt(_attemptKey(childId)) ?? 0;
    return used >= freeAttemptsPerChild;
  }

  Future<void> recordAttempt(String childId) async {
    if (await isPremium()) return;
    final p = await SharedPreferences.getInstance();
    final k = _attemptKey(childId);
    final used = p.getInt(k) ?? 0;
    await p.setInt(k, used + 1);
  }

  Future<void> resetAttempts(String childId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_attemptKey(childId));
  }

  // ---------------- Køb / restore (IAP only)
  Future<PurchaseResult> buyPremium() async {
    if (kIsWeb) {
      return const PurchaseResult(
        success: false,
        message: 'Køb understøttes kun i apps (iOS/Android)',
      );
    }
    return _buyPremiumMobile(onLocalGrant: () => _setPremiumLocally(true));
  }

  Future<PurchaseResult> restorePurchases() async {
    if (kIsWeb) {
      final has = await isPremium();
      return PurchaseResult(
          success: has, message: has ? 'Premium aktiv' : 'Ingen køb fundet');
    }
    return _restoreMobile(onLocalGrant: () => _setPremiumLocally(true));
  }

  // ---------------- Server-side verify helper
  Future<bool> _verifyWithBackend({required PurchaseDetails purchase}) async {
    try {
      final supa = Supabase.instance.client;

      // iOS: base64 kvittering. Android: purchaseToken (string).
      final receipt = purchase.verificationData.serverVerificationData;

      // Undgå dart:io → brug TargetPlatform
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      final platform = isIOS ? 'ios' : 'android';

      final payload = <String, dynamic>{
        'platform': platform,
        'receipt': receipt,
        'productId': productId,
        if (!isIOS) 'packageName': _packageNameAndroid,
      };

      final res = await supa.functions.invoke('iap_verify', body: payload);
      final data =
          res.data is Map ? res.data as Map : json.decode(res.data as String);
      return data['valid'] == true;
    } catch (_) {
      return false;
    }
  }

  // ---------------- Mobile (IAP)
  Future<PurchaseResult> _buyPremiumMobile({
    required Future<void> Function() onLocalGrant,
  }) async {
    final iap = InAppPurchase.instance;

    final available = await iap.isAvailable();
    if (!available) {
      return const PurchaseResult(
          success: false, message: 'Butik ikke tilgængelig');
    }

    final response = await iap.queryProductDetails({productId});
    if (response.error != null) {
      return PurchaseResult(
        success: false,
        message: 'Produkt-forespørgsel fejlede: ${response.error}',
      );
    }
    if (response.productDetails.isEmpty) {
      return const PurchaseResult(
          success: false, message: 'Produkt ikke fundet');
    }
    final product = response.productDetails.first;

    final completer = Completer<PurchaseResult>();
    late final StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      for (final p in purchases) {
        if (p.productID != productId) continue;

        switch (p.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            final ok = await _verifyWithBackend(purchase: p);
            if (!ok) {
              if (p.pendingCompletePurchase) await iap.completePurchase(p);
              if (!completer.isCompleted) {
                completer.complete(const PurchaseResult(
                  success: false,
                  message: 'Kvittering afvist',
                ));
              }
              break;
            }

            await onLocalGrant();

            if (p.pendingCompletePurchase) {
              await iap.completePurchase(p);
            }
            if (!completer.isCompleted) {
              completer.complete(const PurchaseResult(
                success: true,
                message: 'Køb verificeret',
              ));
            }
            break;

          case PurchaseStatus.error:
            if (!completer.isCompleted) {
              completer.complete(PurchaseResult(
                success: false,
                message: p.error?.message ?? 'Ukendt betalingsfejl',
              ));
            }
            break;

          case PurchaseStatus.pending:
          case PurchaseStatus.canceled:
            // afvent/ignorer
            break;
        }
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        completer.complete(PurchaseResult(success: false, message: '$e'));
      }
    });

    final started = await iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      await sub.cancel();
      return const PurchaseResult(
          success: false, message: 'Køb blev afvist/afbrydt');
    }

    final result = await completer.future.timeout(
      const Duration(minutes: 2),
      onTimeout: () =>
          const PurchaseResult(success: false, message: 'Timeout under køb'),
    );
    await sub.cancel();
    return result;
  }

  Future<PurchaseResult> _restoreMobile({
    required Future<void> Function() onLocalGrant,
  }) async {
    final iap = InAppPurchase.instance;

    final available = await iap.isAvailable();
    if (!available) {
      return const PurchaseResult(
          success: false, message: 'Butik ikke tilgængelig');
    }

    final completer = Completer<PurchaseResult>();
    late final StreamSubscription<List<PurchaseDetails>> sub;

    sub = iap.purchaseStream.listen((purchases) async {
      var found = false;
      for (final p in purchases) {
        if (p.productID == productId &&
            (p.status == PurchaseStatus.purchased ||
                p.status == PurchaseStatus.restored)) {
          final ok = await _verifyWithBackend(purchase: p);
          if (ok) {
            await onLocalGrant();
            found = true;
          }
          if (p.pendingCompletePurchase) {
            await iap.completePurchase(p);
          }
        }
      }
      if (!completer.isCompleted) {
        completer.complete(PurchaseResult(
          success: found,
          message: found ? 'Premium genskabt' : 'Ingen gyldige køb fundet',
        ));
      }
    }, onError: (e) {
      if (!completer.isCompleted) {
        completer.complete(PurchaseResult(success: false, message: '$e'));
      }
    });

    await iap.restorePurchases();

    final result = await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () =>
          const PurchaseResult(success: false, message: 'Timeout ved restore'),
    );
    await sub.cancel();
    return result;
  }

  /// DEV only: Toggler premium lokalt – kun i debug builds.
  Future<void> devSetPremium(bool value) async {
    assert(() {
      return true; // aktiveret i debug
    }());
    await _setPremiumLocally(value);
  }

  /// Hjælper der læser lokal premium og returnerer den (kan kaldes efter køb/restore)
  Future<bool> getPremiumStatus() async => isPremium();
}
