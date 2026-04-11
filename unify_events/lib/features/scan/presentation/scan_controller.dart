import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ScanState {
  final bool isProcessing;
  final bool isSuccess;
  final String? errorMessage;
  final String? participantName;

  ScanState({
    this.isProcessing = false,
    this.isSuccess = false,
    this.errorMessage,
    this.participantName,
  });

  ScanState copyWith({
    bool? isProcessing,
    bool? isSuccess,
    String? errorMessage,
    String? participantName,
  }) {
    return ScanState(
      isProcessing: isProcessing ?? this.isProcessing,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      participantName: participantName,
    );
  }
}

class ScanController extends StateNotifier<ScanState> {
  final Dio _dio;
  final Ref _ref;

  ScanController(this._dio, this._ref) : super(ScanState());

  Future<void> processQR(String token) async {
    if (state.isProcessing) return;
    state = state.copyWith(isProcessing: true, isSuccess: false, errorMessage: null, participantName: null);

    try {
      final response = await _dio.post('/checkin/qr/', data: {
        "qr_token": token,
      });

      if (response.statusCode == 200) {
        state = state.copyWith(
          isProcessing: false,
          isSuccess: true,
          participantName: response.data['participant_name'] ?? 'Participant',
        );
      } else {
        state = state.copyWith(
          isProcessing: false,
          isSuccess: false,
          errorMessage: "Invalid QR",
        );
      }
    } on DioException catch (e) {
      String errMsg = "Invalid QR";
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map) {
          final errStr = data.toString();
          if (errStr.contains('Already checked-in')) {
            errMsg = 'Participant already signed in';
          } else if (errStr.contains('Not allowed')) {
            errMsg = 'Access denied for this event';
          }
        }
      }
      state = state.copyWith(
        isProcessing: false,
        isSuccess: false,
        errorMessage: errMsg,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        isSuccess: false,
        errorMessage: "Invalid QR",
      );
    }
  }

  void reset() {
    state = ScanState();
  }
}

final scanControllerProvider = StateNotifierProvider<ScanController, ScanState>((ref) {
  final dio = ref.watch(dioProvider);
  return ScanController(dio, ref);
});
