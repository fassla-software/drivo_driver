import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/register_route_request_model.dart';
import '../domain/models/register_route_response_model.dart';
import '../domain/models/rest_stop_model.dart';
import '../domain/services/register_route_service_interface.dart';

class RegisterRouteController extends GetxController {
  final RegisterRouteServiceInterface registerRouteServiceInterface;
  Function(String message, Color backgroundColor,
      {IconData icon, Duration duration})? onShowSnackBar;

  RegisterRouteController({required this.registerRouteServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Helper method to show snackbar with better error handling
  Future<void> _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
    required IconData icon,
    Duration duration = const Duration(seconds: 3),
  }) async {
    try {
      // Add a small delay to ensure UI is ready
      await Future.delayed(const Duration(milliseconds: 500));

      // Use callback if available, otherwise fallback to Get.context
      if (onShowSnackBar != null) {
        onShowSnackBar!(message, backgroundColor,
            icon: icon, duration: duration);
      } else if (Get.context != null) {
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      Text(
                        message,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            duration: duration,
            backgroundColor: backgroundColor,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(Get.context!).hideCurrentSnackBar();
              },
            ),
          ),
        );
      } else {
        // Fallback: print to console if context is not available
        print('====> Snackbar not shown (no context): $title - $message');
      }
    } catch (e) {
      // Fallback: print to console if snackbar fails
      print('====> Snackbar error: $e');
      print('====> Snackbar message: $title - $message');
    }
  }

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

  final List<RestStopModel> _restStops = [];
  List<RestStopModel> get restStops => _restStops;

  // Polyline encoding
  String _encodedPolyline = '';
  String get encodedPolyline => _encodedPolyline;

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
      if (seats <= 0 || seats > 50) {
        _showValidationError('seats_must_be_between_1_and_50'.tr);
        return false;
      }
    } catch (e) {
      _showValidationError('please_enter_valid_number_of_seats'.tr);
      return false;
    }

    // Validate vehicle ID
    // if (vehicleIdController.text.isEmpty) {
    //   _showValidationError('please_enter_vehicle_id'.tr);
    //   return false;
    // }

    // Validate age limits if provided
    if (minAgeController.text.isNotEmpty || maxAgeController.text.isNotEmpty) {
      try {
        int? minAge = minAgeController.text.isNotEmpty
            ? int.parse(minAgeController.text)
            : null;
        int? maxAge = maxAgeController.text.isNotEmpty
            ? int.parse(maxAgeController.text)
            : null;

        if (minAge != null && (minAge < 13 || minAge > 100)) {
          _showValidationError('minimum_age_must_be_between_13_and_100'.tr);
          return false;
        }

        if (maxAge != null && (maxAge < 13 || maxAge > 100)) {
          _showValidationError('maximum_age_must_be_between_13_and_100'.tr);
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
                      _buildDataSection('🗺️ Route Polyline', [
                        'Status: ${data['encodedPolyline'].isNotEmpty ? 'Generated' : 'Not generated'}',
                        'Length: ${data['encodedPolyline'].length} characters',
                        if (data['encodedPolyline'].isNotEmpty)
                          'Preview: ${data['encodedPolyline'].length > 30 ? '${data['encodedPolyline'].substring(0, 30)}...' : data['encodedPolyline']}',
                      ]),
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
                      onPressed: () => Navigator.pop(Get.context!),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(Get.context!);
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

    // Generate encoded polyline before sending request
    await generateEncodedPolyline();

    // Check if polyline was generated successfully
    if (_encodedPolyline.isEmpty) {
      print('====> Warning: Polyline is empty, proceeding anyway');
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
        allowLuggage: _allowLuggage ? 1 : 0,
        restStops: _restStops,
        encodedPolyline: encodedPolyline,
      );

      // Call the API service
      _registerRouteResponse =
          await registerRouteServiceInterface.registerRoute(requestModel);

      _isLoading = false;
      update();

      // Check if we got a response
      if (_registerRouteResponse == null) {
        await _showSnackbar(
          title: 'error'.tr,
          message: 'no_response_from_server'.tr,
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 4),
        );
        return;
      }

      // Check if the request was successful
      if (_registerRouteResponse!.success) {
        // Success
        await _showSnackbar(
          title: 'success'.tr,
          message: _registerRouteResponse!.message,
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );

        // Clear the form
        // _clearForm();

        // Navigate back or to a success screen
        if (Get.context != null) {
          Navigator.pop(Get.context!);
        }
      } else {
        // Handle API error
        String errorMessage =
            _registerRouteResponse?.message ?? 'failed_to_register_route'.tr;

        // Show error message
        await _showSnackbar(
          title: 'error'.tr,
          message: errorMessage,
          backgroundColor: Colors.red,
          icon: Icons.error,
          duration: const Duration(seconds: 4),
        );

        // Log the error for debugging
        print('====> Register Route Error: $errorMessage');
        print('====> Response Data: ${_registerRouteResponse?.data}');
      }
    } catch (e) {
      _isLoading = false;
      update();

      // Log the exception for debugging
      print('====> Register Route Exception: $e');
      print('====> Exception Type: ${e.runtimeType}');

      String errorMessage = 'network_error_please_try_again'.tr;

      if (e.toString().contains('timeout')) {
        errorMessage = 'request_timeout_please_try_again'.tr;
      } else if (e.toString().contains('socket') ||
          e.toString().contains('network')) {
        errorMessage = 'check_your_internet_and_try_again'.tr;
      } else if (e.toString().contains('connection')) {
        errorMessage = 'no_internet_connection'.tr;
      } else if (e.toString().contains('format')) {
        errorMessage = 'invalid_data_format'.tr;
      } else if (e.toString().contains('parse')) {
        errorMessage = 'invalid_response_format'.tr;
      }

      await _showSnackbar(
        title: 'error'.tr,
        message: errorMessage,
        backgroundColor: Colors.red,
        icon: Icons.wifi_off,
        duration: const Duration(seconds: 4),
      );
    }
  }

  // Method to show current form data for debugging
  Future<void> debugFormData() async {
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

    await _showSnackbar(
      title: 'Debug Data'.tr,
      message: 'Check console for form data',
      backgroundColor: Colors.blue,
      icon: Icons.bug_report,
      duration: const Duration(seconds: 2),
    );
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
      'encodedPolyline': _encodedPolyline,
    };
  }

  // Method to generate encoded polyline from coordinates
  Future<void> generateEncodedPolyline() async {
    try {
      // Validate that we have start and end coordinates
      if (startLatController.text.isEmpty ||
          startLngController.text.isEmpty ||
          endLatController.text.isEmpty ||
          endLngController.text.isEmpty) {
        print('====> Cannot generate polyline: Missing coordinates');
        _encodedPolyline = '';
        return;
      }

      // Parse coordinates
      double startLat = double.parse(startLatController.text);
      double startLng = double.parse(startLngController.text);
      double endLat = double.parse(endLatController.text);
      double endLng = double.parse(endLngController.text);

      // Validate coordinates are reasonable
      if (startLat < -90 ||
          startLat > 90 ||
          endLat < -90 ||
          endLat > 90 ||
          startLng < -180 ||
          startLng > 180 ||
          endLng < -180 ||
          endLng > 180) {
        print('====> Invalid coordinates detected');
        _encodedPolyline = '';
        return;
      }

      // Try to get detailed route from Google Maps API first
      String? detailedPolyline = await _getDetailedRouteFromGoogleMaps(
          startLat, startLng, endLat, endLng);

      if (detailedPolyline != null && detailedPolyline.isNotEmpty) {
        // Use Google Maps detailed route
        _encodedPolyline = detailedPolyline;
        print('====> Using Google Maps detailed polyline');
      } else {
        // Fallback to simple polyline with rest stops
        List<Map<String, double>> coordinates = [
          {'lat': startLat, 'lng': startLng}, // Start point
        ];

        // Add rest stops if any
        for (final restStop in _restStops) {
          coordinates.add({
            'lat': restStop.lat,
            'lng': restStop.lng,
          });
        }

        // Add end point
        coordinates.add({'lat': endLat, 'lng': endLng});

        // Generate simple encoded polyline
        _encodedPolyline = _encodePolyline(coordinates);
        print('====> Using simple polyline with rest stops');
      }

      print('====> Generated encoded polyline: $_encodedPolyline');
      print('====> Polyline length: ${_encodedPolyline.length} characters');

      // Update UI to reflect the new polyline
      update();
    } catch (e) {
      print('====> Error generating encoded polyline: $e');
      _encodedPolyline = '';
      update();
    }
  }

  // Get detailed route from Google Maps API
  Future<String?> _getDetailedRouteFromGoogleMaps(
      double startLat, double startLng, double endLat, double endLng) async {
    try {
      // Google Maps API key (you should use your own key)
      const String apiKey = 'AIzaSyBEBg6ItImxrxhsGbv7G9KNyvy1gr2MGwo';

      // Build waypoints string for rest stops
      String waypoints = '';
      if (_restStops.isNotEmpty) {
        waypoints =
            _restStops.map((stop) => '${stop.lat},${stop.lng}').join('|');
      }

      // Build URL
      String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=$startLat,$startLng&'
          'destination=$endLat,$endLng&'
          '${waypoints.isNotEmpty ? 'waypoints=$waypoints&' : ''}'
          'key=$apiKey&'
          'mode=driving';

      print('====> Google Maps API URL: $url');

      // Make HTTP request
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylineString = route['overview_polyline']['points'];

          print('====> Google Maps polyline received: $polylineString');
          return polylineString;
        } else {
          print('====> Google Maps API error: ${data['status']}');
          return null;
        }
      } else {
        print('====> Google Maps API HTTP error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('====> Error calling Google Maps API: $e');
      return null;
    }
  }

  // Polyline encoding algorithm (Google's polyline algorithm)
  String _encodePolyline(List<Map<String, double>> coordinates) {
    if (coordinates.isEmpty) return '';

    String encoded = '';
    int prevLat = 0;
    int prevLng = 0;

    for (final coord in coordinates) {
      int lat = (coord['lat']! * 1e5).round();
      int lng = (coord['lng']! * 1e5).round();

      int dLat = lat - prevLat;
      int dLng = lng - prevLng;

      encoded += _encodeSignedNumber(dLat);
      encoded += _encodeSignedNumber(dLng);

      prevLat = lat;
      prevLng = lng;
    }

    return encoded;
  }

  // Encode a signed number for polyline
  String _encodeSignedNumber(int num) {
    int sgnNum = num << 1;
    if (num < 0) {
      sgnNum = ~sgnNum;
    }
    return _encodeNumber(sgnNum);
  }

  // Encode a number for polyline
  String _encodeNumber(int num) {
    String encoded = '';
    while (num >= 0x20) {
      encoded += String.fromCharCode(((num & 0x1F) | 0x20) + 63);
      num >>= 5;
    }
    encoded += String.fromCharCode(num + 63);
    return encoded;
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
