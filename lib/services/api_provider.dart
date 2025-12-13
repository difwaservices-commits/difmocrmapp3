import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_application_difmo/services/api_service.dart';

enum ApiStatus { initial, loading, success, error }

class ApiState {
  final ApiStatus status;
  final String? message;
  final Map<String, dynamic>? data;

  const ApiState({this.status = ApiStatus.initial, this.message, this.data});

  ApiState copyWith({
    ApiStatus? status,
    String? message,
    Map<String, dynamic>? data,
  }) {
    return ApiState(
      status: status ?? this.status,
      message: message ?? this.message,
      data: data ?? this.data,
    );
  }
}

class LocationActionNotifier extends Notifier<ApiState> {
  @override
  ApiState build() {
    return const ApiState();
  }

  Future<void> checkIn(
    String employeeId,
    double latitude,
    double longitude,
    String location,
    String notes,
  ) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final result = await ApiService.checkIn(
        employeeId,
        latitude,
        longitude,
        location,
        notes,
      );
      state = state.copyWith(
        status: ApiStatus.success,
        data: result,
        message: "Checked In Successfully!",
      );
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }

  Future<void> checkOut(
    String attendanceId,
    double latitude,
    double longitude,
    String notes,
  ) async {
    state = state.copyWith(status: ApiStatus.loading);
    try {
      final result = await ApiService.checkOut(
        attendanceId,
        latitude,
        longitude,
        notes,
      );
      state = state.copyWith(
        status: ApiStatus.success,
        data: result,
        message: "Checked Out Successfully!",
      );
    } catch (e) {
      state = state.copyWith(status: ApiStatus.error, message: e.toString());
    }
  }

  void reset() {
    state = const ApiState();
  }
}

final locationActionProvider =
    NotifierProvider<LocationActionNotifier, ApiState>(
      LocationActionNotifier.new,
    );
