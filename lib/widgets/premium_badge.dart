import 'package:flutter/material.dart';
import 'package:sproki/services/paywall_service.dart';
import 'package:sproki/screens/premium_screen.dart';

class PremiumBadge extends StatefulWidget {
  /// Hvis true kan man tappe badgen for at åbne Premium-siden.
  final bool tappable;

  /// Ekstra padding rundt om badgen (fx i AppBar actions).
  final EdgeInsetsGeometry padding;

  /// Tekst når brugeren er premium.
  final String premiumText;

  /// Tekst når brugeren er gratis.
  final String freeText;

  const PremiumBadge({
    super.key,
    this.tappable = true,
    this.padding = const EdgeInsets.only(right: 12),
    this.premiumText = 'Premium aktiv',
    this.freeText = 'Gratis',
  });

  @override
  State<PremiumBadge> createState() => _PremiumBadgeState();
}

class _PremiumBadgeState extends State<PremiumBadge>
    with WidgetsBindingObserver {
  bool _premium = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Opdater når app’en kommer i fokus igen (godt efter køb/restore).
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final has = await PaywallService.instance.getPremiumStatus();
    if (!mounted) return;
    setState(() {
      _premium = has;
      _loading = false;
    });
  }

  void _openPremiumScreen() {
    if (!widget.tappable) return;
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (_) => const PremiumScreen()),
        )
        .then((_) => _refresh()); // kom tilbage → tjek igen
  }

  @override
  Widget build(BuildContext context) {
    final color = _premium ? Colors.green[600] : Colors.grey[400];
    final text = _premium ? widget.premiumText : widget.freeText;

    final badge = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (_loading)
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white)),
          )
        else
          Icon(_premium ? Icons.verified : Icons.lock_open,
              size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ]),
    );

    final wrapped = Padding(
      padding: widget.padding,
      child: widget.tappable
          ? InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _openPremiumScreen,
              child: badge)
          : badge,
    );

    return wrapped;
  }
}
