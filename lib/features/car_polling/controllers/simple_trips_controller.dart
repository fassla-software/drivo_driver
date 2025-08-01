import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/api_checker.dart';
import '../domain/models/simple_trip_model.dart';
import '../domain/services/current_trips_service_interface.dart';
import '../screens/simple_trip_map_screen.dart';

class SimpleTripsController extends GetxController implements GetxService {
  final CurrentTripsServiceInterface currentTripsServiceInterface;

  SimpleTripsController({required this.currentTripsServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  bool _isStartingTrip = false;
  bool get isStartingTrip => _isStartingTrip;

  String? _startingTripRouteId;
  String? get startingTripRouteId => _startingTripRouteId;

  SimpleTripsResponseModel? _tripsResponse;
  SimpleTripsResponseModel? get tripsResponse => _tripsResponse;

  List<SimpleTripModel> _trips = [];
  List<SimpleTripModel> get trips => _trips;

  @override
  void onInit() {
    super.onInit();
    print('=== SimpleTripsController onInit called ===');
    getCurrentTrips();
  }

  /// Get current trips from API
  Future<void> getCurrentTrips({bool isRefresh = false}) async {
    print('=== getCurrentTrips called, isRefresh: $isRefresh ===');

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
        _tripsResponse = SimpleTripsResponseModel.fromJson(response.body);

        if (_tripsResponse?.data != null) {
          _trips = _tripsResponse!.data!;
          print('=== Loaded ${_trips.length} trips ===');

          // Debug: Check passenger coordinates for each trip
          for (int i = 0; i < _trips.length; i++) {
            final trip = _trips[i];
            print('=== Trip $i (ID: ${trip.id}): ===');
            print(
                '===   Passenger coordinates: ${trip.passengerCoordinates?.length ?? 0} ===');
            print('===   Passengers: ${trip.passengers?.length ?? 0} ===');
            if (trip.passengerCoordinates != null) {
              for (int j = 0; j < trip.passengerCoordinates!.length; j++) {
                final coord = trip.passengerCoordinates![j];
                print(
                    '===     Coord $j: type=${coord.type}, coords=${coord.coordinates} ===');
              }
            }
          }
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
        message: 'failed_to_load_trips'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
      ));
    } finally {
      _isLoading = false;
      _isRefreshing = false;
      update();
    }
  }

  /// Refresh trips
  Future<void> refreshTrips() async {
    await getCurrentTrips(isRefresh: true);
  }

  /// Get pending trips
  List<SimpleTripModel> get pendingTrips {
    return _trips.where((trip) => trip.tripStatus == 'pending').toList();
  }

  /// Get ongoing trips
  List<SimpleTripModel> get ongoingTrips {
    return _trips.where((trip) => trip.tripStatus == 'ongoing').toList();
  }

  /// Get completed trips
  List<SimpleTripModel> get completedTrips {
    return _trips.where((trip) => trip.tripStatus == 'completed').toList();
  }

  /// Get trip status color
  Color getTripStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'ongoing':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  /// Get trip status display text
  String getTripStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'pending'.tr;
      case 'ongoing':
        return 'ongoing'.tr;
      case 'completed':
        return 'completed'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  /// Get available seats for a trip
  int getAvailableSeats(SimpleTripModel trip) {
    return trip.availableSeats ?? trip.seats ?? 0;
  }

  /// Start a trip
  Future<void> startTrip(int tripId) async {
    _isStartingTrip = true;
    _startingTripRouteId = tripId.toString();
    update();

    try {
      print('=== Starting trip for ID: $tripId ===');

      Response response = await currentTripsServiceInterface.startTrip(tripId);

      print(
          '=== Start Trip API Response - Status Code: ${response.statusCode} ===');
      print('=== Start Trip API Response - Body: ${response.body} ===');

      if (response.statusCode == 200) {
        Get.showSnackbar(GetSnackBar(
          title: 'success'.tr,
          message: 'trip_started_successfully'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));

        // Refresh the trips list
        await getCurrentTrips(isRefresh: true);

        // Get the updated trip data
        SimpleTripModel? updatedTrip =
            _trips.firstWhereOrNull((trip) => trip.id == tripId);
        if (updatedTrip != null) {
          // Navigate to simple trip map screen
          Get.to(() => SimpleTripMapScreen(trip: updatedTrip));
        }
      } else {
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
  bool isTripBeingStarted(int tripId) {
    return _isStartingTrip && _startingTripRouteId == tripId.toString();
  }

  /// Clear all data
  void _clearData() {
    _trips.clear();
    _tripsResponse = null;
  }

  /// Clear all data and update UI
  void clearData() {
    _clearData();
    update();
  }
}
