import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/api_checker.dart';
import '../domain/models/current_trips_with_passengers_response_model.dart';
import '../domain/services/current_trips_service_interface.dart';
import '../screens/carpool_trip_map_screen.dart';

class CurrentTripsController extends GetxController implements GetxService {
  final CurrentTripsServiceInterface currentTripsServiceInterface;

  CurrentTripsController({required this.currentTripsServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isStartingTrip = false;
  bool get isStartingTrip => _isStartingTrip;

  String? _startingTripRouteId;
  String? get startingTripRouteId => _startingTripRouteId;

  CurrentTripsWithPassengersResponseModel? _currentTripsResponse;
  CurrentTripsWithPassengersResponseModel? get currentTripsResponse =>
      _currentTripsResponse;

  CurrentTripsData? _currentTripsData;
  CurrentTripsData? get currentTripsData => _currentTripsData;

  List<CurrentTrip> _currentTrips = [];
  List<CurrentTrip> get currentTrips => _currentTrips;

  int _totalTrips = 0;
  int get totalTrips => _totalTrips;

  int _upcomingTrips = 0;
  int get upcomingTrips => _upcomingTrips;

  int _ongoingTrips = 0;
  int get ongoingTrips => _ongoingTrips;

  int _completedTrips = 0;
  int get completedTrips => _completedTrips;

  @override
  void onInit() {
    super.onInit();
    print('=== CurrentTripsController onInit called ===');
    getCurrentTripsWithPassengers();
  }

  /// Get current trips with passengers from API
  Future<void> getCurrentTripsWithPassengers({bool isRefresh = false}) async {
    print(
        '=== getCurrentTripsWithPassengers called, isRefresh: $isRefresh ===');

    if (isRefresh) {
      _isRefreshing = true;
    } else {
      _isLoading = true;
    }
    update();

    try {
      print('=== Making API call to getCurrentTripsWithPassengers ===');
      Response response =
          await currentTripsServiceInterface.getCurrentTripsWithPassengers();

      print('=== API Response - Status Code: ${response.statusCode} ===');
      print('=== API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        _currentTripsResponse =
            CurrentTripsWithPassengersResponseModel.fromJson(response.body);

        if (_currentTripsResponse?.data != null) {
          _currentTripsData = _currentTripsResponse!.data!;
          _currentTrips = _currentTripsData?.currentTrips ?? [];

          // Update statistics
          _totalTrips = _currentTripsData?.totalTrips ?? 0;
          _upcomingTrips = _currentTripsData?.upcomingTrips ?? 0;
          _ongoingTrips = _currentTripsData?.ongoingTrips ?? 0;
          _completedTrips = _currentTripsData?.completedTrips ?? 0;
        } else {
          _clearData();
        }
      } else {
        _clearData();
        ApiChecker.checkApi(response);
      }
    } catch (e) {
      print('=== API Error: $e ===');
      _clearData();
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'failed_to_load_current_trips'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
      ));
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      update();
    }
  }

  /// Refresh current trips
  Future<void> refreshCurrentTrips() async {
    await getCurrentTripsWithPassengers(isRefresh: true);
  }

  /// Get trip by index
  CurrentTrip? getTripAt(int index) {
    if (index >= 0 && index < _currentTrips.length) {
      return _currentTrips[index];
    }
    return null;
  }

  /// Get trip by route ID
  CurrentTrip? getTripByRouteId(int routeId) {
    try {
      return _currentTrips.firstWhere((trip) => trip.routeId == routeId);
    } catch (e) {
      return null;
    }
  }

  /// Get total current trips count
  int get totalCurrentTripsCount => _currentTrips.length;

  /// Check if trip has accepted passengers
  bool tripHasPassengers(CurrentTrip trip) {
    return trip.totalAcceptedPassengers != null &&
        trip.totalAcceptedPassengers! > 0;
  }

  /// Get available seats for a trip
  int getAvailableSeats(CurrentTrip trip) {
    int totalSeats = trip.seatsAvailable ?? 0;
    int occupiedSeats = trip.totalAcceptedPassengers ?? 0;
    return totalSeats - occupiedSeats;
  }

  /// Get route features as a list of strings
  List<String> getRouteFeatures(CurrentTrip trip) {
    List<String> features = [];

    if (trip.routePreferences?.isAc == true) features.add('AC');
    if (trip.routePreferences?.hasMusic == true) features.add('Music');
    if (trip.routePreferences?.hasScreenEntertainment == true)
      features.add('Entertainment');
    if (trip.routePreferences?.allowLuggage == true) features.add('Luggage');
    if (trip.routePreferences?.isSmokingAllowed == true)
      features.add('Smoking');

    return features;
  }

  /// Get trip status color
  Color getTripStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return Colors.purple;
      case 'ongoing':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get trip status display text
  String getTripStatusDisplayText(String? status) {
    switch (status?.toLowerCase()) {
      case 'scheduled':
        return 'scheduled'.tr;
      case 'ongoing':
        return 'ongoing'.tr;
      case 'pending':
        return 'pending'.tr;
      case 'completed':
        return 'completed'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  /// Get passenger status color
  Color getPassengerStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'picked_up':
        return Colors.blue;
      case 'dropped_off':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Get passenger status display text
  String getPassengerStatusDisplayText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'picked_up':
        return 'picked_up'.tr;
      case 'dropped_off':
        return 'dropped_off'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  /// Filter trips by status
  List<CurrentTrip> getFilteredTrips(String status) {
    return _currentTrips
        .where((trip) => trip.tripStatus?.toLowerCase() == status.toLowerCase())
        .toList();
  }

  /// Get ongoing trips
  List<CurrentTrip> get ongoingTripsList {
    return getFilteredTrips('ongoing');
  }

  /// Get pending trips
  List<CurrentTrip> get pendingTripsList {
    return getFilteredTrips('pending');
  }

  /// Get completed trips
  List<CurrentTrip> get completedTripsList {
    return getFilteredTrips('completed');
  }

  /// Get trip duration text
  String getTripDurationText(CurrentTrip trip) {
    if (trip.startTime != null && trip.endTime != null) {
      try {
        DateTime startTime = DateTime.parse(trip.startTime!);
        DateTime endTime = DateTime.parse(trip.endTime!);
        Duration duration = endTime.difference(startTime);

        int hours = duration.inHours;
        int minutes = duration.inMinutes.remainder(60);

        if (hours > 0) {
          return '${hours}h ${minutes}m';
        } else {
          return '${minutes}m';
        }
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  /// Get formatted start time
  String getFormattedStartTime(CurrentTrip trip) {
    if (trip.startTime != null) {
      try {
        DateTime startTime = DateTime.parse(trip.startTime!);
        return '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  /// Get formatted start date
  String getFormattedStartDate(CurrentTrip trip) {
    if (trip.startTime != null) {
      try {
        DateTime startTime = DateTime.parse(trip.startTime!);
        return '${startTime.day}/${startTime.month}/${startTime.year}';
      } catch (e) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  /// Calculate total earnings from current trips
  double get totalEarnings {
    return _currentTrips.fold(
        0.0, (sum, trip) => sum + (trip.totalFareFromPassengers ?? 0.0));
  }

  /// Get trip by passenger ID
  CurrentTrip? getTripByPassengerId(int passengerId) {
    for (CurrentTrip trip in _currentTrips) {
      if (trip.acceptedPassengers != null) {
        for (AcceptedPassenger passenger in trip.acceptedPassengers!) {
          if (passenger.passengerId == passengerId) {
            return trip;
          }
        }
      }
    }
    return null;
  }

  /// Get passenger from trip
  AcceptedPassenger? getPassengerFromTrip(CurrentTrip trip, int passengerId) {
    if (trip.acceptedPassengers != null) {
      try {
        return trip.acceptedPassengers!
            .firstWhere((passenger) => passenger.passengerId == passengerId);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  /// Clear all data
  void _clearData() {
    _currentTrips.clear();
    _currentTripsResponse = null;
    _currentTripsData = null;
    _totalTrips = 0;
    _upcomingTrips = 0;
    _ongoingTrips = 0;
    _completedTrips = 0;
  }

  /// Clear all data and update UI
  void clearData() {
    _clearData();
    update();
  }

  /// Start a trip
  Future<void> startTrip(int carpoolRouteId) async {
    _isStartingTrip = true;
    _startingTripRouteId = carpoolRouteId.toString();
    update();

    try {
      print('=== Starting trip for route ID: $carpoolRouteId ===');

      Response response =
          await currentTripsServiceInterface.startTrip(carpoolRouteId);

      print(
          '=== Start Trip API Response - Status Code: ${response.statusCode} ===');
      print('=== Start Trip API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        // Show success message
        Get.showSnackbar(GetSnackBar(
          title: 'success'.tr,
          message: 'trip_started_successfully'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));

        // Refresh the trips list to get updated status
        await getCurrentTripsWithPassengers(isRefresh: true);

        // Get the updated trip data
        CurrentTrip? updatedTrip = getTripByRouteId(carpoolRouteId);
        if (updatedTrip != null) {
          // Navigate to carpool trip map screen with the trip data
          Get.to(() => CarpoolTripMapScreen(trip: updatedTrip));
        } else {
          // Fallback: just show success message if trip data not found
          print(
              'Warning: Updated trip data not found for route ID $carpoolRouteId');
        }
      } else {
        // Handle error response
        String errorMessage = 'failed_to_start_trip'.tr;
        if (response.body != null && response.body['message'] != null) {
          errorMessage = response.body['message'];
        }

        Get.showSnackbar(GetSnackBar(
          title: 'error'.tr,
          message: errorMessage,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ));

        ApiChecker.checkApi(response);
      }
    } catch (e) {
      print('=== Start Trip Error: $e ===');
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'failed_to_start_trip'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.red,
      ));
    } finally {
      _isStartingTrip = false;
      _startingTripRouteId = null;
      update();
    }
  }

  /// Check if a specific trip is being started
  bool isTripBeingStarted(int routeId) {
    return _isStartingTrip && _startingTripRouteId == routeId.toString();
  }

  /// Get scheduled trips
  List<CurrentTrip> get scheduledTripsList {
    return getFilteredTrips('scheduled');
  }
}
