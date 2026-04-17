import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ScanState {
  final bool isProcessing;
  final bool isSuccess;
  final String? errorMessage;
  final String? participantName;
  final Map<String, dynamic>? extraData; // For "Already checked-in" info

  ScanState({
    this.isProcessing = false,
    this.isSuccess = false,
    this.errorMessage,
    this.participantName,
    this.extraData,
  });

  ScanState copyWith({
    bool? isProcessing,
    bool? isSuccess,
    String? errorMessage,
    String? participantName,
    Map<String, dynamic>? extraData,
  }) {
    return ScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      participantName: participantName ?? this.participantName,
      extraData: extraData ?? this.extraData,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final Dio _dio;
  final Ref _ref;

  ScanController(this._dio, this._ref) : super(ScanState());

  void setProcessing(bool value) {
    state = state.copyWith(isProcessing: value);
  }

  Future<Map<String, dynamic>?> fetchPreview(String token) async {
    if (state.isProcessing) return null;
    state = state.copyWith(isProcessing: true, errorMessage: null);

    try {
      final response = await _dio.post(
        '/checkin/qr-preview/',
        data: {"qr_token": token},
      );

      if (response.statusCode == 200) {
        state = state.copyWith(isProcessing: false);
        final data = response.data;
        if (data is Map && 
            (data['already_checked_in'] == true || 
             data['error'].toString().contains('Already checked-in'))) {
           return {
            "already_checked_in": true,
            "participant_name": data["participant_name"],
            "event_name": data["event_name"],
            "slot": data["slot"],
          };
        }
        return response.data;
      }
    } on DioError catch (e) {
      state = state.copyWith(isProcessing: false);
      final data = e.response?.data;
      if (data is Map && 
          (data['already_checked_in'] == true || 
           data.toString().contains('Already checked-in'))) {
        return {
          "already_checked_in": true,
          "participant_name": data["participant_name"],
          "event_name": data["event_name"],
          "slot": data["slot"],
        };
      }
      rethrow;
    } catch (e) {
      state = state.copyWith(isProcessing: false);
      rethrow;
    }
    return null;
  }

  Future<Map<String, dynamic>> checkIn(String token) async {
    state = state.copyWith(isProcessing: true, errorMessage: null);
    try {
      final response = await _dio.post(
        '/checkin/qr/',
        data: {"qr_token": token},
      );
      state = state.copyWith(isProcessing: false, isSuccess: true);
      return response.data;
    } on DioError catch (e) {
      state = state.copyWith(isProcessing: false, isSuccess: false);
      rethrow;
    } catch (e) {
      state = state.copyWith(isProcessing: false, isSuccess: false);
      rethrow;
    }
  }

  void markSuccess(String name) {
    state = state.copyWith(
      isSuccess: true,
      participantName: name,
      isProcessing: false,
    );
  }

  void reset() {
    state = ScanState();
  }
}

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>(
  (ref) {
    final dio = ref.watch(dioProvider);
    return ScanController(dio, ref);
  },
);
