import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../network/auth_interceptor.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import 'models/pending_checkin.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

final syncServiceProvider = Provider((ref) => SyncService(ref));

class SyncService {
  final Ref ref;
  late final Dio _dio;
  bool _isSyncing = false;
  late StreamSubscription _connectivitySub;

  SyncService(this.ref) {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ));
    _dio.interceptors.add(AuthInterceptor(_dio, SecureStorageService()));

    // Listen to network changes
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final hasConnection = results.any((result) => 
        result == ConnectivityResult.mobile || 
        result == ConnectivityResult.wifi || 
        result == ConnectivityResult.ethernet
      );

      if (hasConnection) {
        syncPendingCheckins();
      }
    });

    // Try initial sync
    syncPendingCheckins();
  }

  void dispose() {
    _connectivitySub.cancel();
  }

  Future<void> syncPendingCheckins() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final box = Hive.box<PendingCheckin>('checkin_queue');
      final pendingItems = box.values.where((e) => e.status == 'pending').toList();

      for (var item in pendingItems) {
        await _syncSingleCheckin(item);
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncSingleCheckin(PendingCheckin item) async {
    try {
      // Perform the checkin using the correct endpoint, POST /checkin/qr/
      // Need to emulate the checkin done by scanner. Wait, what endpoint does scan API use? 
      // User says: POST /checkin/qr/ does check-in directly? Actually in scan_controller, 
      final response = await _dio.post('/checkin/qr/', data: {"qr_token": item.qrToken});
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        item.status = 'success';
        item.save();
      }
    } on DioError catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 404) {
        final resData = e.response?.data?.toString() ?? '';
        if (resData.contains('Already checked-in')) {
          item.status = 'success';
        } else {
          item.status = 'failed';
        }
        item.save();
      } else if (status == 401) {
        // Auth issue, ignore and it will trigger logout outside
      } else {
        // Server or Network error
        item.retries++;
        if (item.retries >= 3) {
          item.status = 'failed';
        }
        item.save();
        // Basic exponential backoff simulation for current sync batch
        await Future.delayed(Duration(seconds: 2 * item.retries));
      }
    } catch (_) {
      // Unknown error (no network), retry later
      item.retries++;
      if (item.retries >= 3) {
        item.status = 'failed';
      }
      item.save();
      await Future.delayed(Duration(seconds: 2 * item.retries));
    }
  }

  Future<void> addPendingCheckin(String qrToken, [String? eventId]) async {
    final box = Hive.box<PendingCheckin>('checkin_queue');
    
    // Check for duplicates
    final existing = box.values.any((e) => e.qrToken == qrToken && e.status == 'pending');
    if (existing) return;

    final pending = PendingCheckin(
      qrToken: qrToken,
      scannedAt: DateTime.now(),
      eventId: eventId,
      status: 'pending',
    );
    await box.add(pending);

    // Attempt to sync immediately
    syncPendingCheckins();
  }
}
