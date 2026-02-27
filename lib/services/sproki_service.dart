import 'package:dio/dio.dart';

import '../api/api_client.dart';
import '../models/child.dart';
import '../models/exercise.dart';
import '../models/report.dart';

class SprokiMe {
  SprokiMe({
    required this.role,
    required this.institutionId,
  });

  final String role;
  final int? institutionId;

  factory SprokiMe.fromJson(Map<String, dynamic> json) {
    return SprokiMe(
      role: (json['role'] as String?) ?? '',
      institutionId: (json['institution_id'] as num?)?.toInt(),
    );
  }
}

class InviteResult {
  InviteResult({
    required this.email,
    required this.role,
  });

  final String email;
  final String role;

  factory InviteResult.fromJson(Map<String, dynamic> json) {
    return InviteResult(
      email: (json['email'] as String?) ?? '',
      role: (json['role'] as String?) ?? '',
    );
  }
}

class PendingInvite {
  PendingInvite({
    required this.pending,
    this.role,
    this.institutionId,
    this.childId,
  });

  final bool pending;
  final String? role;
  final int? institutionId;
  final int? childId;

  factory PendingInvite.fromJson(Map<String, dynamic> json) {
    return PendingInvite(
      pending: (json['pending'] as bool?) ??
          (json['invite_pending'] as bool?) ??
          false,
      role: (json['role'] as String?) ?? (json['invite_role'] as String?),
      institutionId: (json['institution_id'] as num?)?.toInt() ??
          (json['invite_institution_id'] as num?)?.toInt(),
      childId: (json['child_id'] as num?)?.toInt() ??
          (json['invite_child_id'] as num?)?.toInt(),
    );
  }
}

class SprokiService {
  SprokiService(ApiClient apiClient) : _apiClient = apiClient;

  ApiClient _apiClient;

  Dio get _dio => _apiClient.dio;

  // Cache hvilken pending-invite endpoint der virker (så vi ikke prøver 3 hver gang).
  String? _workingPendingInvitePath;

  // Hvis ingen endpoints findes -> stop med at probe i resten af app-sessionen.
  bool _pendingInviteUnsupported = false;

  // Allow swapping ApiClient after startup (basePath resolver).
  void setApiClient(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  // ----------------------------
  // Helpers
  // ----------------------------

  Map<String, dynamic> _unwrapObject(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'];
      if (inner is Map<String, dynamic>) return inner;
      return data;
    }
    return <String, dynamic>{};
  }

  List<dynamic> _unwrapList(dynamic data) {
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List);
    }
    if (data is List) return data;
    return const [];
  }

  int _readInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  bool _readBool(dynamic v) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return false;
  }

  bool _isSoftNetworkError(DioException e) {
    // Timeouts / connection / DNS / socket osv.
    if (e.type == DioExceptionType.connectionTimeout) return true;
    if (e.type == DioExceptionType.sendTimeout) return true;
    if (e.type == DioExceptionType.receiveTimeout) return true;

    // Dio bruger ofte "unknown" ved socket/dns/handshake.
    if (e.type == DioExceptionType.unknown) return true;
    if (e.type == DioExceptionType.connectionError) return true;

    return false;
  }

  PendingInvite? _tryBuildPendingInviteFromPayload(Map<String, dynamic> obj) {
    final hasPendingFlag =
        obj.containsKey('pending') || obj.containsKey('invite_pending');

    final isPending =
        _readBool(obj['pending']) || _readBool(obj['invite_pending']);

    if (hasPendingFlag) {
      final parsed = PendingInvite.fromJson(obj);

      if (isPending && !parsed.pending) {
        return PendingInvite(
          pending: true,
          role: parsed.role,
          institutionId: parsed.institutionId,
          childId: parsed.childId,
        );
      }

      return parsed;
    }

    final hasInvitePayload = (obj['invite_role'] != null) ||
        (obj['invite_institution_id'] != null) ||
        (obj['invite_child_id'] != null);

    if (hasInvitePayload) {
      return PendingInvite(
        pending: true,
        role: obj['invite_role'] as String?,
        institutionId: (obj['invite_institution_id'] as num?)?.toInt(),
        childId: (obj['invite_child_id'] as num?)?.toInt(),
      );
    }

    return null;
  }

  // ----------------------------
  // Children
  // ----------------------------

  Future<List<Child>> listChildren() async {
    final res = await _dio.get<dynamic>('/children');
    final list = _unwrapList(res.data);

    return list
        .whereType<Map>()
        .map((e) => Child.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Child> createChild({
    required String name,
    int? birthYear,
  }) async {
    final payload = <String, dynamic>{
      'name': name.trim(),
    };

    if (birthYear != null) {
      payload['birth_year'] = birthYear;
    }

    final res = await _dio.post<dynamic>(
      '/children',
      data: payload,
      options: Options(extra: const {'idempotent': true}),
    );

    final obj = _unwrapObject(res.data);
    return Child.fromJson(obj);
  }

  // ----------------------------
  // Child detail
  // ----------------------------

  Future<ChildReportAnalysis> latestReport(int childId) async {
    final res = await _dio.get<dynamic>('/children/$childId/latest-report');
    final obj = _unwrapObject(res.data);
    return ChildReportAnalysis.fromJson(obj);
  }

  Future<List<ExerciseItem>> recommendedExercises(int childId) async {
    final res =
        await _dio.get<dynamic>('/children/$childId/recommended-exercises');
    final list = _unwrapList(res.data);

    return list
        .whereType<Map>()
        .map((e) => ExerciseItem.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  // ----------------------------
  // Training / attempts
  // ----------------------------

  Future<int> startTraining({
    required int childId,
    required List<int> exerciseIds,
  }) async {
    final res = await _dio.post<dynamic>(
      '/attempts',
      data: <String, dynamic>{
        'child_id': childId,
        'exercise_ids': exerciseIds,
      },
      options: Options(extra: const {'idempotent': true}),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = _unwrapObject(data);
      final attemptIdAny =
          inner['id'] ?? inner['attempt_id'] ?? inner['attemptId'];
      return _readInt(attemptIdAny);
    }

    return 0;
  }

  Future<int> postAttempt({
    required int childId,
    required int exerciseId,
    required bool correct,
  }) async {
    final res = await _dio.post<dynamic>(
      '/attempts',
      data: <String, dynamic>{
        'child_id': childId,
        'exercise_id': exerciseId,
        'correct': correct,
      },
      options: Options(extra: const {'idempotent': true}),
    );

    final data = res.data;
    if (data is Map<String, dynamic>) {
      final inner = _unwrapObject(data);
      final attemptIdAny =
          inner['id'] ?? inner['attempt_id'] ?? inner['attemptId'];
      return _readInt(attemptIdAny);
    }

    return 0;
  }

  // ----------------------------
  // Invites
  // ----------------------------

  Future<InviteResult> createInvite({
    required String email,
    required String role,
    required int institutionId,
  }) async {
    final res = await _dio.post<dynamic>(
      '/invites',
      data: <String, dynamic>{
        'email': email,
        'role': role,
        'institution_id': institutionId,
      },
      options: Options(extra: const {'idempotent': true}),
    );

    final obj = _unwrapObject(res.data);
    return InviteResult.fromJson(obj);
  }

  Future<void> acceptInvite() async {
    try {
      await _dio.post<dynamic>(
        '/me/accept-invite',
        data: <String, dynamic>{},
        options: Options(extra: const {'idempotent': true}),
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;

      // Backend har ikke endpoint endnu -> treat as "not supported"
      if (status == 404 || status == 405 || status == 501) return;

      // Netværk/timeout/etc -> do nothing (UI må ikke crashe/flippe ud)
      if (_isSoftNetworkError(e)) return;

      rethrow;
    }
  }

  // ----------------------------
  // Me
  // ----------------------------

  Future<SprokiMe> me() async {
    final res = await _dio.get<dynamic>('/me');
    final obj = _unwrapObject(res.data);
    return SprokiMe.fromJson(obj);
  }

  Future<PendingInvite?> pendingInvite() async {
    if (_pendingInviteUnsupported) return null;

    final paths = _workingPendingInvitePath != null
        ? <String>[_workingPendingInvitePath!]
        : const <String>[
            '/me/pending-invite',
            '/me/invite/pending',
            '/me/invite',
          ];

    for (final path in paths) {
      try {
        final res = await _dio.get<dynamic>(
          path,
          options: Options(
            extra: const {
              'suppress_404_log': true,
            },
          ),
        );

        // Vi fandt et endpoint der virker -> cache det
        _workingPendingInvitePath = path;

        final data = res.data;
        if (data is Map<String, dynamic>) {
          final obj = _unwrapObject(data);

          final parsed = _tryBuildPendingInviteFromPayload(obj);
          if (parsed != null) return parsed;

          return PendingInvite(pending: false);
        }

        return PendingInvite(pending: false);
      } on DioException catch (e) {
        final status = e.response?.statusCode;

        // Ikke implementeret / ikke fundet -> prøv næste
        if (status == 404 || status == 405 || status == 501) {
          // Hvis vi kun prøvede cached path, så er den død -> marker unsupported og stop
          if (_workingPendingInvitePath != null &&
              paths.length == 1 &&
              paths.first == _workingPendingInvitePath) {
            _pendingInviteUnsupported = true;
            _workingPendingInvitePath = null;
            return null;
          }

          continue;
        }

        // Transient netværk -> skip (ingen errors i UI auto-flow)
        if (_isSoftNetworkError(e)) return null;

        rethrow;
      }
    }

    // Ingen endpoints findes -> stop probing for resten af sessionen
    _pendingInviteUnsupported = true;
    _workingPendingInvitePath = null;
    return null;
  }
}