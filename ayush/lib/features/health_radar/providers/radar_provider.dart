import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class RadarState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  RadarState({this.isLoading = false, this.error, this.data});

  RadarState copyWith({bool? isLoading, String? error, Map<String, dynamic>? data}) {
    return RadarState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      data: data ?? this.data,
    );
  }
}

class RadarNotifier extends StateNotifier<RadarState> {
  final Dio _dio;

  RadarNotifier(this._dio) : super(RadarState());

  Future<void> fetchRadarAnalysis(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/predict/radar/$userId');
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, data: response.data);
      } else {
        state = state.copyWith(isLoading: false, error: 'Failed to fetch radar analysis');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Analysis is still generating. Check back in a moment!');
    }
  }
}

final radarProvider = StateNotifierProvider<RadarNotifier, RadarState>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return RadarNotifier(dioClient);
});
