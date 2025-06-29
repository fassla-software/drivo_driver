import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/models/register_route_request_model.dart';
import '../domain/models/register_route_response_model.dart';
import '../domain/models/rest_stop_model.dart';
import '../domain/services/register_route_service_interface.dart';
import 'dart:convert';

class RegisterRouteController extends GetxController {
  final RegisterRouteServiceInterface registerRouteServiceInterface;

  RegisterRouteController({required this.registerRouteServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  RegisterRouteResponseModel? _registerRouteResponse;
  RegisterRouteResponseModel? get registerRouteResponse =>
      _registerRouteResponse;

  // Form controllers
  final TextEditingController startLatController = TextEditingController();
  final TextEditingController startLngController = TextEditingController();
  final TextEditingController endLatController = TextEditingController();
  final TextEditingController endLngController = TextEditingController();
  final TextEditingController startTimeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController vehicleIdController = TextEditingController();
  final TextEditingController seatsController = TextEditingController();
  final TextEditingController minAgeController = TextEditingController();
  final TextEditingController maxAgeController = TextEditingController();

  // Form values
  String _rideType = 'work';
  String get rideType => _rideType;

  bool _isAc = true;
  bool get isAc => _isAc;

  bool _isSmokingAllowed = false;
  bool get isSmokingAllowed => _isSmokingAllowed;

  bool _hasMusic = true;
  bool get hasMusic => _hasMusic;

  String _allowedGender = 'both';
  String get allowedGender => _allowedGender;

  bool _hasScreenEntertainment = false;
  bool get hasScreenEntertainment => _hasScreenEntertainment;

  bool _allowLuggage = true;
  bool get allowLuggage => _allowLuggage;

  List<RestStopModel> _restStops = [];
  List<RestStopModel> get restStops => _restStops;

  void setRideType(String type) {
    _rideType = type;
    update();
  }

  void setIsAc(bool value) {
    _isAc = value;
    update();
  }

  void setIsSmokingAllowed(bool value) {
    _isSmokingAllowed = value;
    update();
  }

  void setHasMusic(bool value) {
    _hasMusic = value;
    update();
  }

  void setAllowedGender(String gender) {
    _allowedGender = gender;
    update();
  }

  void setHasScreenEntertainment(bool value) {
    _hasScreenEntertainment = value;
    update();
  }

  void setAllowLuggage(bool value) {
    _allowLuggage = value;
    update();
  }

  void addRestStop(RestStopModel restStop) {
    _restStops.add(restStop);
    update();
  }

  void removeRestStop(int index) {
    if (index >= 0 && index < _restStops.length) {
      _restStops.removeAt(index);
      update();
    }
  }

  void clearRestStops() {
    _restStops.clear();
    update();
  }

  Future<void> registerRoute() async {
    // Show debug dialog with all collected data first
    await _showDataPreviewDialog();
  }

  bool _validateForm() {
    // Validate coordinates
    if (startLatController.text.isEmpty || startLngController.text.isEmpty) {
      _showValidationError('please_select_starting_point'.tr);
      return false;
    }

    if (endLatController.text.isEmpty || endLngController.text.isEmpty) {
      _showValidationError('please_select_destination'.tr);
      return false;
    }

    // Validate coordinates are valid numbers
    try {
      double.parse(startLatController.text);
      double.parse(startLngController.text);
      double.parse(endLatController.text);
      double.parse(endLngController.text);
    } catch (e) {
      _showValidationError('invalid_coordinates_please_use_map_picker'.tr);
      return false;
    }

    // Validate start time
    if (startTimeController.text.isEmpty) {
      _showValidationError('please_select_departure_time'.tr);
      return false;
    }

    // Validate price
    if (priceController.text.isEmpty) {
      _showValidationError('please_enter_price_per_seat'.tr);
      return false;
    }

    try {
      double price = double.parse(priceController.text);
      if (price <= 0) {
        _showValidationError('price_must_be_greater_than_zero'.tr);
        return false;
      }
    } catch (e) {
      _showValidationError('please_enter_valid_price'.tr);
      return false;
    }

    // Validate seats
    if (seatsController.text.isEmpty) {
      _showValidationError('please_enter_available_seats'.tr);
      return false;
    }

    try {
      int seats = int.parse(seatsController.text);
      if (seats <= 0 || seats > 8) {
        _showValidationError('seats_must_be_between_1_and_8'.tr);
        return false;
      }
    } catch (e) {
      _showValidationError('please_enter_valid_number_of_seats'.tr);
      return false;
    }

    // Validate vehicle ID
    if (vehicleIdController.text.isEmpty) {
      _showValidationError('please_enter_vehicle_id'.tr);
      return false;
    }

    // Validate age limits if provided
    if (minAgeController.text.isNotEmpty || maxAgeController.text.isNotEmpty) {
      try {
        int? minAge = minAgeController.text.isNotEmpty
            ? int.parse(minAgeController.text)
            : null;
        int? maxAge = maxAgeController.text.isNotEmpty
            ? int.parse(maxAgeController.text)
            : null;

        if (minAge != null && (minAge < 16 || minAge > 80)) {
          _showValidationError('minimum_age_must_be_between_16_and_80'.tr);
          return false;
        }

        if (maxAge != null && (maxAge < 16 || maxAge > 80)) {
          _showValidationError('maximum_age_must_be_between_16_and_80'.tr);
          return false;
        }

        if (minAge != null && maxAge != null && minAge > maxAge) {
          _showValidationError(
              'minimum_age_cannot_be_greater_than_maximum_age'.tr);
          return false;
        }
      } catch (e) {
        _showValidationError('please_enter_valid_age_limits'.tr);
        return false;
      }
    }

    // Validate rest stops
    for (int i = 0; i < _restStops.length; i++) {
      final restStop = _restStops[i];
      if (restStop.name.trim().isEmpty) {
        _showValidationError('rest_stop_${i + 1}_name_is_required'.tr);
        return false;
      }
    }

    return true;
  }

  void _showValidationError(String message) {
    Get.showSnackbar(GetSnackBar(
      title: 'validation_error'.tr,
      message: message,
      duration: const Duration(seconds: 3),
      backgroundColor: Colors.orange,
      icon: const Icon(Icons.warning, color: Colors.white),
    ));
  }

  void _clearForm() {
    // Clear all text controllers
    startLatController.clear();
    startLngController.clear();
    endLatController.clear();
    endLngController.clear();
    startTimeController.clear();
    priceController.clear();
    vehicleIdController.clear();
    seatsController.clear();
    minAgeController.clear();
    maxAgeController.clear();

    // Reset dropdown values
    _rideType = 'work';
    _allowedGender = 'both';

    // Reset boolean values
    _isAc = false;
    _isSmokingAllowed = false;
    _hasMusic = false;
    _hasScreenEntertainment = false;
    _allowLuggage = false;

    // Clear rest stops
    _restStops.clear();

    update();
  }

  // Method to show data preview dialog
  Future<void> _showDataPreviewDialog() async {
    final data = getCurrentFormData();

    await Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 400),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.preview,
                    color: Theme.of(Get.context!).primaryColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Route Data Preview',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(Get.context!).primaryColor,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Data content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDataSection('🎯 Route Information', [
                        'Start: ${data['startCoordinates']['lat']}, ${data['startCoordinates']['lng']}',
                        'End: ${data['endCoordinates']['lat']}, ${data['endCoordinates']['lng']}',
                        'Departure: ${data['startTime']}',
                      ]),
                      _buildDataSection('🚗 Vehicle & Pricing', [
                        'Price per seat: ${data['price']} EGP',
                        'Available seats: ${data['seats']}',
                        'Vehicle ID: ${data['vehicleId']}',
                        'Ride type: ${data['rideType']}',
                      ]),
                      _buildDataSection('👥 Passenger Preferences', [
                        'Min age: ${data['ageRestrictions']['minAge']}',
                        'Max age: ${data['ageRestrictions']['maxAge']}',
                        'Allowed gender: ${data['allowedGender']}',
                      ]),
                      _buildDataSection('✨ Vehicle Features', [
                        'AC: ${data['features']['isAc'] ? 'Yes' : 'No'}',
                        'Smoking: ${data['features']['isSmokingAllowed'] ? 'Yes' : 'No'}',
                        'Music: ${data['features']['hasMusic'] ? 'Yes' : 'No'}',
                        'Entertainment: ${data['features']['hasScreenEntertainment'] ? 'Yes' : 'No'}',
                        'Luggage: ${data['features']['allowLuggage'] ? 'Yes' : 'No'}',
                      ]),
                      if (data['restStops'].isNotEmpty)
                        _buildDataSection(
                            '🛑 Rest Stops',
                            (data['restStops'] as List)
                                .map((stop) =>
                                    '${stop['name']}: ${stop['lat']}, ${stop['lng']}')
                                .toList()),
                    ],
                  ),
                ),
              ),

              const Divider(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        _proceedWithRegistration();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(Get.context!).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Send to API'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  Widget _buildDataSection(String title, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: items
                  .map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          item,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  // Method to actually proceed with registration
  Future<void> _proceedWithRegistration() async {
    if (!_validateForm()) {
      return;
    }

    _isLoading = true;
    update();

    try {
      // Prepare the request model with all collected data
      final requestModel = RegisterRouteRequestModel(
        startLat: double.parse(startLatController.text),
        startLng: double.parse(startLngController.text),
        endLat: double.parse(endLatController.text),
        endLng: double.parse(endLngController.text),
        startTime: startTimeController.text,
        price: double.parse(priceController.text),
        vehicleId: vehicleIdController.text,
        rideType: _rideType,
        seatsAvailable: int.parse(seatsController.text),
        allowedAgeMin: minAgeController.text.isNotEmpty
            ? int.parse(minAgeController.text)
            : 0,
        allowedAgeMax: maxAgeController.text.isNotEmpty
            ? int.parse(maxAgeController.text)
            : 100,
        allowedGender: _allowedGender,
        isAc: _isAc ? 1 : 0,
        isSmokingAllowed: _isSmokingAllowed ? 1 : 0,
        hasMusic: _hasMusic ? 1 : 0,
        hasScreenEntertainment: _hasScreenEntertainment ? 1 : 0,
        allowLuggage: _allowLuggage,
        restStops: _restStops,
      );

      // Call the API service
      _registerRouteResponse =
          await registerRouteServiceInterface.registerRoute(requestModel);

      _isLoading = false;
      update();

      if (_registerRouteResponse != null && _registerRouteResponse!.success) {
        // Success
        Get.showSnackbar(GetSnackBar(
          title: 'success'.tr,
          message: _registerRouteResponse!.message,
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.green,
          icon: const Icon(Icons.check_circle, color: Colors.white),
        ));

        // Clear the form
        _clearForm();

        // Navigate back or to a success screen
        Get.back();
      } else {
        // Handle API error
        String errorMessage =
            _registerRouteResponse?.message ?? 'failed_to_register_route'.tr;

        Get.showSnackbar(GetSnackBar(
          title: 'error'.tr,
          message: errorMessage,
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
          icon: const Icon(Icons.error, color: Colors.white),
        ));
      }
    } catch (e) {
      _isLoading = false;
      update();

      String errorMessage = 'network_error_please_try_again'.tr;

      if (e.toString().contains('timeout')) {
        errorMessage = 'request_timeout_please_try_again'.tr;
      } else if (e.toString().contains('socket')) {
        errorMessage = 'no_internet_connection'.tr;
      }

      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: errorMessage,
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.red,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
      ));
    }
  }

  // Method to show current form data for debugging
  void debugFormData() {
    final data = getCurrentFormData();
    print("=== REGISTER ROUTE DATA ===");
    print("Start Coordinates: ${data['startCoordinates']}");
    print("End Coordinates: ${data['endCoordinates']}");
    print("Start Time: ${data['startTime']}");
    print("Price: ${data['price']}");
    print("Vehicle ID: ${data['vehicleId']}");
    print("Ride Type: ${data['rideType']}");
    print("Seats: ${data['seats']}");
    print("Age Restrictions: ${data['ageRestrictions']}");
    print("Allowed Gender: ${data['allowedGender']}");
    print("Features: ${data['features']}");
    print("Rest Stops: ${data['restStops']}");
    print("=========================");

    Get.showSnackbar(GetSnackBar(
      title: 'Debug Data'.tr,
      message: 'Check console for form data',
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.bug_report, color: Colors.white),
    ));
  }

  // Method to get current form data for debugging
  Map<String, dynamic> getCurrentFormData() {
    return {
      'startCoordinates': {
        'lat': startLatController.text,
        'lng': startLngController.text,
      },
      'endCoordinates': {
        'lat': endLatController.text,
        'lng': endLngController.text,
      },
      'startTime': startTimeController.text,
      'price': priceController.text,
      'vehicleId': vehicleIdController.text,
      'rideType': _rideType,
      'seats': seatsController.text,
      'ageRestrictions': {
        'minAge': minAgeController.text,
        'maxAge': maxAgeController.text,
      },
      'allowedGender': _allowedGender,
      'features': {
        'isAc': _isAc,
        'isSmokingAllowed': _isSmokingAllowed,
        'hasMusic': _hasMusic,
        'hasScreenEntertainment': _hasScreenEntertainment,
        'allowLuggage': _allowLuggage,
      },
      'restStops': _restStops
          .map((stop) => {
                'name': stop.name,
                'lat': stop.lat,
                'lng': stop.lng,
              })
          .toList(),
    };
  }

  @override
  void onClose() {
    startLatController.dispose();
    startLngController.dispose();
    endLatController.dispose();
    endLngController.dispose();
    startTimeController.dispose();
    priceController.dispose();
    vehicleIdController.dispose();
    seatsController.dispose();
    minAgeController.dispose();
    maxAgeController.dispose();
    super.onClose();
  }
}
