import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ScanState {
  final bool isProcessing;
  final bool isSuccess;
  final String? participantName;

  ScanState({this.isProcessing = false, this.isSuccess = false, this.participantName});

  ScanState copyWith({bool? isProcessing, bool? isSuccess, String? participantName}) {
    return ScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      participantName: participantName ?? this.participantName,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final Dio _dio;
  ScanController(this._dio) : super(ScanState());

  Future<Map<String, dynamic>?> fetchPreview(String token) async {
    state = state.copyWith(isProcessing: true);
    try {
      final response = await _dio.post('/checkin/qr-preview/', data: {"qr_token": token});
      state = state.copyWith(isProcessing: false);
      return response.data; // Includes "status", "participant_name", "event_name"
    } on DioException catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkIn(String token) async {
    state = state.copyWith(isProcessing: true);
    try {
      final response = await _dio.post('/checkin/qr/', data: {"qr_token": token});
      state = state.copyWith(isProcessing: false, isSuccess: true, participantName: response.data["participant_name"]);
      return response.data;
    } on DioException catch (e) {
      state = state.copyWith(isProcessing: false, isSuccess: false);
      rethrow;
    }
  }

  void reset() => state = ScanState();
}

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(
  (ref) => ScanController(ref.watch(dioProvider)),
);