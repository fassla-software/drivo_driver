import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../util/images.dart';
import '../../../util/app_constants.dart';
import '../../../features/location/controllers/location_controller.dart';
import '../domain/models/current_trips_with_passengers_response_model.dart';
import '../../../features/auth/controllers/auth_controller.dart';

class CarpoolTripMapController extends GetxController {
  // Map controller
  GoogleMapController? _mapController;
  GoogleMapController? get mapController => _mapController;

  // Reactive state variables
  final RxSet<Marker> _markers = <Marker>{}.obs;
  final RxSet<Polyline> _polylines = <Polyline>{}.obs;
  final RxBool _isLoading = true.obs;
  final RxBool _isLoadingPolylines = false.obs;
  final Rx<LatLng?> _centerPosition = Rx<LatLng?>(null);
  final Rx<LatLng?> _driverPosition = Rx<LatLng?>(null);
  final RxDouble _driverBearing = 0.0.obs;

  // Getters for reactive state
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  bool get isLoading => _isLoading.value;
  bool get isLoadingPolylines => _isLoadingPolylines.value;
  LatLng? get centerPosition => _centerPosition.value;
  LatLng? get driverPosition => _driverPosition.value;
  double get driverBearing => _driverBearing.value;

  // Google API key and polyline decoder
  static const String _googleApiKey = 'AIzaSyBEBg6ItImxrxhsGbv7G9KNyvy1gr2MGwo';
  final PolylinePoints polylinePoints = PolylinePoints();

  // Current trip data
  late CurrentTrip _currentTrip;
  CurrentTrip get currentTrip => _currentTrip;

  // Location tracking
  StreamSubscription<Position>? _locationSubscription;
  bool _isTrackingLocation = false;

  // User proximity tracking
  final RxList<AcceptedPassenger> _nearbyPassengers = <AcceptedPassenger>[].obs;
  final RxBool _isProximityDialogShowing = false.obs;
  static const double _proximityRadius = 100.0; // 100 meters radius
  Timer? _proximityCheckTimer;

  // Passenger pickup tracking
  final RxMap<String, bool> _passengerPickupStatus = <String, bool>{}.obs;
  final RxMap<String, bool> _isPickupInProgress = <String, bool>{}.obs;

  // Initialize with trip data
  void initializeTrip(CurrentTrip trip) {
    _currentTrip = trip;
    _initializePassengerStatus();
    _initializeMap();
  }

  void _initializePassengerStatus() {
    if (_currentTrip.acceptedPassengers != null) {
      for (final passenger in _currentTrip.acceptedPassengers!) {
        _passengerPickupStatus[passenger.carpoolTripId ?? ''] =
            passenger.status == 'picked_up' || passenger.status == 'completed';
        _isPickupInProgress[passenger.carpoolTripId ?? ''] = false;
      }
    }
  }

  // Getters for passenger status
  bool isPassengerPickedUp(String carpoolTripId) {
    return _passengerPickupStatus[carpoolTripId] ?? false;
  }

  bool isPickupInProgress(String carpoolTripId) {
    return _isPickupInProgress[carpoolTripId] ?? false;
  }

  List<AcceptedPassenger> get availablePassengers {
    if (_currentTrip.acceptedPassengers == null) return [];
    return _currentTrip.acceptedPassengers!
        .where((passenger) =>
            passenger.status != 'picked_up' && passenger.status != 'completed')
        .toList();
  }

  List<AcceptedPassenger> get pickedUpPassengers {
    if (_currentTrip.acceptedPassengers == null) return [];
    return _currentTrip.acceptedPassengers!
        .where((passenger) =>
            passenger.status == 'picked_up' || passenger.status == 'completed')
        .toList();
  }

  // Pickup passenger function
  Future<void> pickupPassenger(AcceptedPassenger passenger) async {
    if (passenger.carpoolTripId == null) {
      Get.showSnackbar(GetSnackBar(
        title: 'خطأ',
        message: 'معرف الرحلة غير متوفر',
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Check if pickup is already in progress
    if (isPickupInProgress(passenger.carpoolTripId!)) {
      return;
    }

    try {
      // Set pickup in progress
      _isPickupInProgress[passenger.carpoolTripId!] = true;
      update();

      debugPrint('بدء عملية استلام المستخدم: ${passenger.name}');

      // TODO: Call API to pickup passenger when backend is ready
      // final response = await http.post(
      //   Uri.parse('${AppConstants.baseUrl}/api/driver/pickup-passenger'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer ${Get.find<AuthController>().token}',
      //   },
      //   body: json.encode({
      //     'carpool_trip_id': passenger.carpoolTripId,
      //     'passenger_id': passenger.passengerId,
      //     'pickup_time': DateTime.now().toIso8601String(),
      //     'driver_location': {
      //       'lat': _driverPosition.value?.latitude,
      //       'lng': _driverPosition.value?.longitude,
      //     },
      //   }),
      // );

      // Simulate API call success
      await Future.delayed(Duration(seconds: 1));

      // Update passenger status
      passenger.status = 'picked_up';
      _passengerPickupStatus[passenger.carpoolTripId!] = true;

      // Remove passenger marker from map
      _markers.removeWhere((marker) =>
          marker.markerId.value == 'passenger_${passenger.carpoolTripId}');

      // Remove from nearby passengers list
      _nearbyPassengers.remove(passenger);

      // Update map for passenger status change
      _updateMapForPassengerStatus(passenger);

      Get.showSnackbar(GetSnackBar(
        title: 'تم الاستلام بنجاح',
        message: 'تم استلام ${passenger.name ?? 'المستخدم'} بنجاح',
        backgroundColor: Colors.green,
      ));

      debugPrint('تم استلام المستخدم بنجاح: ${passenger.name}');
    } catch (e) {
      debugPrint('خطأ في استلام المستخدم: $e');
      Get.showSnackbar(GetSnackBar(
        title: 'خطأ',
        message: 'حدث خطأ أثناء استلام المستخدم: $e',
        backgroundColor: Colors.red,
      ));
    } finally {
      // Reset pickup in progress
      _isPickupInProgress[passenger.carpoolTripId!] = false;
      update();
    }
  }

  // Dropoff passenger function
  Future<void> dropoffPassenger(AcceptedPassenger passenger) async {
    if (passenger.carpoolTripId == null) {
      Get.showSnackbar(GetSnackBar(
        title: 'خطأ',
        message: 'معرف الرحلة غير متوفر',
        backgroundColor: Colors.red,
      ));
      return;
    }

    try {
      debugPrint('بدء عملية إنزال المستخدم: ${passenger.name}');

      // TODO: Call API to dropoff passenger when backend is ready
      // final response = await http.post(
      //   Uri.parse('${AppConstants.baseUrl}/api/driver/dropoff-passenger'),
      //   headers: {
      //     'Content-Type': 'application/json',
      //     'Authorization': 'Bearer ${Get.find<AuthController>().token}',
      //   },
      //   body: json.encode({
      //     'carpool_trip_id': passenger.carpoolTripId,
      //     'passenger_id': passenger.passengerId,
      //     'dropoff_time': DateTime.now().toIso8601String(),
      //     'driver_location': {
      //       'lat': _driverPosition.value?.latitude,
      //       'lng': _driverPosition.value?.longitude,
      //     },
      //   }),
      // );

      // Simulate API call success
      await Future.delayed(Duration(seconds: 1));

      // Update passenger status
      passenger.status = 'completed';
      _passengerPickupStatus[passenger.carpoolTripId!] = true;

      // Remove dropoff marker from map
      _markers.removeWhere((marker) =>
          marker.markerId.value == 'dropoff_${passenger.carpoolTripId}');

      // Remove passenger route from map
      _polylines.removeWhere((polyline) =>
          polyline.polylineId.value ==
              'passenger_route_${passenger.carpoolTripId}' ||
          polyline.polylineId.value ==
              'passenger_route_fallback_${passenger.carpoolTripId}');

      // Update map and UI
      update();

      Get.showSnackbar(GetSnackBar(
        title: 'تم الإنزال بنجاح',
        message: 'تم إنزال ${passenger.name ?? 'المستخدم'} بنجاح',
        backgroundColor: Colors.green,
      ));

      debugPrint('تم إنزال المستخدم بنجاح: ${passenger.name}');
    } catch (e) {
      debugPrint('خطأ في إنزال المستخدم: $e');
      Get.showSnackbar(GetSnackBar(
        title: 'خطأ',
        message: 'حدث خطأ أثناء إنزال المستخدم: $e',
        backgroundColor: Colors.red,
      ));
    }
  }

  // Update map when passenger status changes
  void _updateMapForPassengerStatus(AcceptedPassenger passenger) {
    // Remove old passenger route
    _polylines.removeWhere((polyline) =>
        polyline.polylineId.value ==
            'passenger_route_${passenger.carpoolTripId}' ||
        polyline.polylineId.value ==
            'passenger_route_fallback_${passenger.carpoolTripId}');

    // Create new route based on current status
    if (passenger.status == 'picked_up' &&
        passenger.dropoffCoordinates?.lat != null &&
        passenger.dropoffCoordinates?.lng != null) {
      // Create route from current driver position to dropoff
      if (_driverPosition.value != null) {
        _createRouteToDropoff(passenger);
      }
    }

    update();
  }

  // Update passenger routes when driver location changes
  void _updatePassengerRoutesForNewLocation() {
    if (_currentTrip.acceptedPassengers == null) return;

    for (final passenger in _currentTrip.acceptedPassengers!) {
      if (passenger.status == 'picked_up' &&
          passenger.dropoffCoordinates?.lat != null &&
          passenger.dropoffCoordinates?.lng != null) {
        _createRouteToDropoff(passenger);
      }
    }
  }

  // Create route from current position to passenger dropoff
  Future<void> _createRouteToDropoff(AcceptedPassenger passenger) async {
    if (_driverPosition.value == null ||
        passenger.dropoffCoordinates?.lat == null ||
        passenger.dropoffCoordinates?.lng == null) return;

    try {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${_driverPosition.value!.latitude},${_driverPosition.value!.longitude}&'
          'destination=${passenger.dropoffCoordinates!.lat!},${passenger.dropoffCoordinates!.lng!}&'
          'key=$_googleApiKey&'
          'mode=driving';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polylineString = route['overview_polyline']['points'];

          final List<PointLatLng> polylineCoordinates =
              polylinePoints.decodePolyline(polylineString);

          final List<LatLng> roadPoints = polylineCoordinates
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();

          _polylines.add(Polyline(
            polylineId:
                PolylineId('passenger_route_${passenger.carpoolTripId}'),
            points: roadPoints,
            color: Colors.green,
            width: 3,
            patterns: [PatternItem.dash(15), PatternItem.gap(8)],
          ));
        }
      }
    } catch (e) {
      debugPrint('Error creating route to dropoff for ${passenger.name}: $e');

      // Fallback to straight line
      _polylines.add(Polyline(
        polylineId:
            PolylineId('passenger_route_fallback_${passenger.carpoolTripId}'),
        points: [
          _driverPosition.value!,
          LatLng(
            passenger.dropoffCoordinates!.lat!,
            passenger.dropoffCoordinates!.lng!,
          ),
        ],
        color: Colors.green,
        width: 2,
        patterns: [PatternItem.dash(15), PatternItem.gap(8)],
      ));
    }
  }

  void _initializeMap() async {
    try {
      debugPrint('Starting map initialization...');

      _calculateCenterPosition();
      debugPrint('Center position calculated');

      // Set loading to false early so UI can show immediately
      _isLoading.value = false;
      debugPrint('Loading set to false - UI should now show');

      // Create markers in background
      _createMarkers().then((_) {
        debugPrint('Markers created');
      }).catchError((e) {
        debugPrint('Error creating markers: $e');
      });

      // Start location tracking in background with timeout
      _startLocationTrackingWithTimeout();

      // Initialize zone if needed in background
      initializeZone();

      // Create polylines after the UI is loaded (they'll update asynchronously)
      _createPolylines();

      // Start proximity checking for nearby passengers
      _startProximityChecking();

      debugPrint('Map initialization completed');
    } catch (e) {
      debugPrint('Error initializing map: $e');
      _isLoading.value = false;
    }
  }

  // Start location tracking with timeout
  void _startLocationTrackingWithTimeout() async {
    try {
      // Set a timeout for location tracking
      bool locationObtained = false;

      // Start location tracking
      _startLocationTracking();

      // Set a timeout of 10 seconds
      Timer(const Duration(seconds: 10), () {
        if (!locationObtained) {
          debugPrint('Location tracking timeout, using fallback');
          _startLocationTrackingFallback();
        }
      });
    } catch (e) {
      debugPrint('Error in location tracking with timeout: $e');
      _startLocationTrackingFallback();
    }
  }

  void _calculateCenterPosition() {
    if (_currentTrip.startCoordinates != null &&
        _currentTrip.startCoordinates!.length == 2) {
      _centerPosition.value = LatLng(
        _currentTrip.startCoordinates![0],
        _currentTrip.startCoordinates![1],
      );
    } else if (_currentTrip.endCoordinates != null &&
        _currentTrip.endCoordinates!.length == 2) {
      // Fallback to end coordinates if start is not available
      _centerPosition.value = LatLng(
        _currentTrip.endCoordinates![0],
        _currentTrip.endCoordinates![1],
      );
    } else {
      // Fallback to a default position
      _centerPosition.value = const LatLng(30.0444, 31.2357); // Cairo, Egypt
    }
  }

  // Start real-time location tracking
  void _startLocationTracking() async {
    try {
      debugPrint('Starting location tracking...');

      // Check if LocationController is available
      if (!Get.isRegistered<LocationController>()) {
        debugPrint(
            'LocationController not registered, using fallback location');
        await _startLocationTrackingFallback();
        return;
      }

      // Use the existing LocationController to get current location with proper zone handling
      Position position =
          await Get.find<LocationController>().getCurrentLocation(
        isAnimate: false,
        mapController: _mapController,
        callZone: true, // This will get the zone_id
      );

      debugPrint(
          'Location obtained: ${position.latitude}, ${position.longitude}');

      _driverPosition.value = LatLng(position.latitude, position.longitude);
      _driverBearing.value = position.heading;

      // Add driver marker
      await _addDriverMarker(_driverPosition.value!);

      // بدء stream للموقع للتحديث المستمر
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, // دقة عالية
          distanceFilter: 5, // تحديث كل 5 أمتار للحصول على تحديثات أكثر دقة
          timeLimit: const Duration(seconds: 30), // حد زمني للتحديث
        ),
      ).listen((Position position) {
        debugPrint(
            'تم استلام تحديث موقع جديد: ${position.latitude}, ${position.longitude}');
        _updateDriverLocation(position);
      });

      _isTrackingLocation = true;
      debugPrint('Location tracking started successfully');
    } catch (e) {
      debugPrint('Error starting location tracking: $e');
      // Fallback to basic location tracking
      await _startLocationTrackingFallback();
    }
  }

  // Fallback location tracking method
  Future<void> _startLocationTrackingFallback() async {
    try {
      debugPrint('Using fallback location tracking...');

      // Get current position directly
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      _driverPosition.value = LatLng(position.latitude, position.longitude);
      _driverBearing.value = position.heading;

      // Add driver marker
      await _addDriverMarker(_driverPosition.value!);

      // بدء stream للموقع للتحديث المستمر (fallback)
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // تحديث كل 5 أمتار
          timeLimit: const Duration(seconds: 30),
        ),
      ).listen((Position position) {
        debugPrint(
            'تحديث موقع fallback: ${position.latitude}, ${position.longitude}');
        _updateDriverLocation(position);
      });

      _isTrackingLocation = true;
      debugPrint('Fallback location tracking started');
    } catch (e) {
      debugPrint('Error in fallback location tracking: $e');
    }
  }

  // Update driver location and marker
  void _updateDriverLocation(Position position) async {
    try {
      final newPosition = LatLng(position.latitude, position.longitude);

      // تحديث موقع السائق
      _driverPosition.value = newPosition;
      _driverBearing.value = position.heading;

      debugPrint(
          'تم تحديث موقع السائق: ${position.latitude}, ${position.longitude}, الاتجاه: ${position.heading}');

      // تحديث علامة السيارة على الخريطة
      await _updateDriverMarker(newPosition, position.heading);

      // تحديث الموقع في LocationController مع zone_id
      try {
        if (Get.isRegistered<LocationController>()) {
          await Get.find<LocationController>().updateLastLocation(
            position.latitude.toString(),
            position.longitude.toString(),
          );
        }
      } catch (e) {
        debugPrint('خطأ في تحديث الموقع: $e');
      }

      // تحريك الكاميرا لتتبع السائق إذا كان وضع التتبع مفعل
      if (_mapController != null && _isTrackingLocation) {
        try {
          _mapController!.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: newPosition,
                zoom: 16,
                bearing: position.heading,
                tilt: 45,
              ),
            ),
          );
        } catch (e) {
          debugPrint('خطأ في تحريك الكاميرا: $e');
        }
      }

      // تحديث مسارات الركاب المستلمين
      _updatePassengerRoutesForNewLocation();

      // تحديث الواجهة
      update();
    } catch (e) {
      debugPrint('خطأ في تحديث موقع السائق: $e');
    }
  }

  // Add driver marker to map
  Future<void> _addDriverMarker(LatLng position) async {
    try {
      // Remove existing driver marker
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');

      // Create car icon
      Uint8List carIcon =
          await _convertAssetToUnit8List(Images.carIconTop, width: 80);

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: BitmapDescriptor.fromBytes(carIcon),
        rotation: _driverBearing.value,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'Driver Location',
          snippet: 'Current position',
        ),
      );

      _markers.add(driverMarker);
    } catch (e) {
      debugPrint('Error adding driver marker: $e');
    }
  }

  // Update driver marker position and rotation
  Future<void> _updateDriverMarker(LatLng position, double bearing) async {
    try {
      // Remove existing driver marker
      _markers.removeWhere((marker) => marker.markerId.value == 'driver');

      // Create car icon
      Uint8List carIcon =
          await _convertAssetToUnit8List(Images.carIconTop, width: 80);

      final driverMarker = Marker(
        markerId: const MarkerId('driver'),
        position: position,
        icon: BitmapDescriptor.fromBytes(carIcon),
        rotation: bearing,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: 'Driver Location',
          snippet: 'Current position',
        ),
      );

      _markers.add(driverMarker);
    } catch (e) {
      debugPrint('Error updating driver marker: $e');
    }
  }

  // Convert asset to Uint8List for marker icons
  Future<Uint8List> _convertAssetToUnit8List(String imagePath,
      {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    // Create start point marker (Green)
    if (_currentTrip.startCoordinates != null &&
        _currentTrip.startCoordinates!.length == 2) {
      final startMarker = await _createCustomMarker(
        'start',
        LatLng(_currentTrip.startCoordinates![0],
            _currentTrip.startCoordinates![1]),
        'Trip Start',
        _currentTrip.startAddress ?? 'Start Location',
        Colors.green,
        Icons.play_arrow,
      );
      _markers.add(startMarker);
    }

    // Create end point marker (Red)
    if (_currentTrip.endCoordinates != null &&
        _currentTrip.endCoordinates!.length == 2) {
      final endMarker = await _createCustomMarker(
        'end',
        LatLng(
            _currentTrip.endCoordinates![0], _currentTrip.endCoordinates![1]),
        'Trip End',
        _currentTrip.endAddress ?? 'End Location',
        Colors.red,
        Icons.location_on,
      );
      _markers.add(endMarker);
    }

    // Create passenger pickup markers (Blue)
    if (_currentTrip.acceptedPassengers != null) {
      for (int i = 0; i < _currentTrip.acceptedPassengers!.length; i++) {
        final passenger = _currentTrip.acceptedPassengers![i];

        // Pickup marker - only if passenger is not picked up
        if (passenger.status != 'picked_up' &&
            passenger.status != 'completed' &&
            passenger.pickupCoordinates?.lat != null &&
            passenger.pickupCoordinates?.lng != null) {
          final pickupMarker = await _createCustomMarker(
            'passenger_${passenger.carpoolTripId}',
            LatLng(passenger.pickupCoordinates!.lat!,
                passenger.pickupCoordinates!.lng!),
            '${passenger.name ?? 'Passenger'} Pickup',
            '${passenger.pickupAddress ?? 'Pickup Location'}',
            Colors.blue,
            Icons.person_pin_circle,
          );
          _markers.add(pickupMarker);
        }

        // Dropoff marker (Orange)
        if (passenger.dropoffCoordinates?.lat != null &&
            passenger.dropoffCoordinates?.lng != null) {
          final dropoffMarker = await _createCustomMarker(
            'dropoff_${passenger.carpoolTripId}',
            LatLng(passenger.dropoffCoordinates!.lat!,
                passenger.dropoffCoordinates!.lng!),
            '${passenger.name ?? 'Passenger'} Dropoff',
            passenger.pickupAddress ?? 'Dropoff Location',
            Colors.orange,
            Icons.person_pin,
          );
          _markers.add(dropoffMarker);
        }
      }
    }
  }

  void _createPolylines() async {
    _isLoadingPolylines.value = true;

    _polylines.clear();

    // Create main route from start to end with passenger waypoints
    await _createMainRoutePolylines();

    // Create individual passenger pickup/dropoff routes
    await _createPassengerRoutePolylines();

    _isLoadingPolylines.value = false;
  }

  Future<void> _createMainRoutePolylines() async {
    List<LatLng> waypoints = [];

    // Add passenger pickup points as waypoints
    if (_currentTrip.acceptedPassengers != null) {
      for (final passenger in _currentTrip.acceptedPassengers!) {
        if (passenger.pickupCoordinates?.lat != null &&
            passenger.pickupCoordinates?.lng != null) {
          waypoints.add(LatLng(
            passenger.pickupCoordinates!.lat!,
            passenger.pickupCoordinates!.lng!,
          ));
        }
      }
    }

    // Add passenger dropoff points as waypoints
    if (_currentTrip.acceptedPassengers != null) {
      for (final passenger in _currentTrip.acceptedPassengers!) {
        if (passenger.dropoffCoordinates?.lat != null &&
            passenger.dropoffCoordinates?.lng != null) {
          waypoints.add(LatLng(
            passenger.dropoffCoordinates!.lat!,
            passenger.dropoffCoordinates!.lng!,
          ));
        }
      }
    }

    // Create route from start to end with waypoints
    if (_currentTrip.startCoordinates != null &&
        _currentTrip.startCoordinates!.length == 2 &&
        _currentTrip.endCoordinates != null &&
        _currentTrip.endCoordinates!.length == 2) {
      try {
        final String waypointsString = waypoints
            .map((point) => '${point.latitude},${point.longitude}')
            .join('|');

        final String url =
            'https://maps.googleapis.com/maps/api/directions/json?'
            'origin=${_currentTrip.startCoordinates![0]},${_currentTrip.startCoordinates![1]}&'
            'destination=${_currentTrip.endCoordinates![0]},${_currentTrip.endCoordinates![1]}&'
            '${waypointsString.isNotEmpty ? 'waypoints=$waypointsString&' : ''}'
            'key=$_googleApiKey&'
            'mode=driving&'
            'traffic_model=best_guess&'
            'departure_time=now';

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
            final route = data['routes'][0];
            final polylineString = route['overview_polyline']['points'];

            final List<PointLatLng> polylineCoordinates =
                polylinePoints.decodePolyline(polylineString);

            final List<LatLng> roadPoints = polylineCoordinates
                .map((point) => LatLng(point.latitude, point.longitude))
                .toList();

            _polylines.add(Polyline(
              polylineId: const PolylineId('main_route'),
              points: roadPoints,
              color: Get.theme.primaryColor,
              width: 5,
              patterns: [],
            ));
          }
        }
      } catch (e) {
        debugPrint('Error creating main route polylines: $e');
        // Fallback to straight line route
        List<LatLng> fallbackPoints = [];
        fallbackPoints.add(LatLng(
          _currentTrip.startCoordinates![0],
          _currentTrip.startCoordinates![1],
        ));
        fallbackPoints.addAll(waypoints);
        fallbackPoints.add(LatLng(
          _currentTrip.endCoordinates![0],
          _currentTrip.endCoordinates![1],
        ));
        _polylines.add(Polyline(
          polylineId: const PolylineId('main_route_fallback'),
          points: fallbackPoints,
          color: Get.theme.primaryColor,
          width: 4,
          patterns: [],
        ));
      }
    }
  }

  Future<void> _createPassengerRoutePolylines() async {
    if (_currentTrip.acceptedPassengers == null) return;

    for (int i = 0; i < _currentTrip.acceptedPassengers!.length; i++) {
      final passenger = _currentTrip.acceptedPassengers![i];

      // Only create passenger routes for passengers who are not completed
      if (passenger.status != 'completed' &&
          passenger.pickupCoordinates?.lat != null &&
          passenger.pickupCoordinates?.lng != null &&
          passenger.dropoffCoordinates?.lat != null &&
          passenger.dropoffCoordinates?.lng != null) {
        // Choose color based on passenger status
        Color routeColor;
        List<PatternItem> patterns;

        if (passenger.status == 'picked_up') {
          // Passenger is picked up, show route to dropoff
          routeColor = Colors.green;
          patterns = [PatternItem.dash(15), PatternItem.gap(8)];
        } else {
          // Passenger is waiting, show route from pickup to dropoff
          routeColor = Colors.blue;
          patterns = [PatternItem.dash(20), PatternItem.gap(10)];
        }

        try {
          final String url =
              'https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${passenger.pickupCoordinates!.lat!},${passenger.pickupCoordinates!.lng!}&'
              'destination=${passenger.dropoffCoordinates!.lat!},${passenger.dropoffCoordinates!.lng!}&'
              'key=$_googleApiKey&'
              'mode=driving';

          final response = await http.get(Uri.parse(url));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
              final route = data['routes'][0];
              final polylineString = route['overview_polyline']['points'];

              final List<PointLatLng> polylineCoordinates =
                  polylinePoints.decodePolyline(polylineString);

              final List<LatLng> roadPoints = polylineCoordinates
                  .map((point) => LatLng(point.latitude, point.longitude))
                  .toList();

              _polylines.add(Polyline(
                polylineId:
                    PolylineId('passenger_route_${passenger.carpoolTripId}'),
                points: roadPoints,
                color: routeColor,
                width: 3,
                patterns: patterns,
              ));
            }
          }
        } catch (e) {
          debugPrint(
              'Error creating passenger route for ${passenger.name}: $e');

          // Fallback to straight line if API fails
          _polylines.add(Polyline(
            polylineId: PolylineId(
                'passenger_route_fallback_${passenger.carpoolTripId}'),
            points: [
              LatLng(
                passenger.pickupCoordinates!.lat!,
                passenger.pickupCoordinates!.lng!,
              ),
              LatLng(
                passenger.dropoffCoordinates!.lat!,
                passenger.dropoffCoordinates!.lng!,
              ),
            ],
            color: routeColor,
            width: 2,
            patterns: patterns,
          ));
        }
      }
    }
  }

  Future<Marker> _createCustomMarker(
    String markerId,
    LatLng position,
    String title,
    String snippet,
    Color color,
    IconData icon,
  ) async {
    final BitmapDescriptor markerIcon =
        await _createCustomMarkerIcon(color, icon);

    return Marker(
      markerId: MarkerId(markerId),
      position: position,
      icon: markerIcon,
      infoWindow: InfoWindow(
        title: title,
        snippet: snippet,
      ),
    );
  }

  Future<BitmapDescriptor> _createCustomMarkerIcon(
      Color color, IconData icon) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = color;
    const double size = 20.0; // Reduced from 60.0 to 35.0 for smaller icons

    // Draw circle background
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2,
      paint,
    );

    // Draw white border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0; // Reduced border thickness for smaller size
    canvas.drawCircle(
      const Offset(size / 2, size / 2),
      size / 2 - 1.5, // Adjusted border radius for smaller border width
      borderPaint,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size * 0.6, // Icon size relative to circle
        fontFamily: icon.fontFamily,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
    // Fit all markers on the map after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      fitMarkersOnMap();
    });
  }

  void fitMarkersOnMap() {
    if (_mapController == null) return;

    final List<LatLng> positions = [];

    // إضافة إحداثيات الرحلة الأساسية
    if (_currentTrip.startCoordinates != null) {
      positions.add(LatLng(
        _currentTrip.startCoordinates![0],
        _currentTrip.startCoordinates![1],
      ));
    }

    if (_currentTrip.endCoordinates != null) {
      positions.add(LatLng(
        _currentTrip.endCoordinates![0],
        _currentTrip.endCoordinates![1],
      ));
    }

    // إضافة مواقع السائق إذا كان متاحًا
    if (_driverPosition.value != null) {
      positions.add(_driverPosition.value!);
    }

    // إضافة مواقع الركاب
    positions.addAll(_markers.map((marker) => marker.position));

    if (positions.isEmpty) {
      // Fallback to default position
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(const LatLng(30.0444, 31.2357), 14),
      );
      return;
    }

    if (positions.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(positions.first, 16),
      );
      return;
    }

    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (LatLng position in positions) {
      minLat = minLat < position.latitude ? minLat : position.latitude;
      maxLat = maxLat > position.latitude ? maxLat : position.latitude;
      minLng = minLng < position.longitude ? minLng : position.longitude;
      maxLng = maxLng > position.longitude ? maxLng : position.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100),
    );
  }

  // Camera control methods
  void followDriver() {
    if (_driverPosition.value != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: _driverPosition.value!,
            zoom: 16,
            bearing: _driverBearing.value,
            tilt: 45,
          ),
        ),
      );
    } else if (_currentTrip.startCoordinates != null &&
        _mapController != null) {
      // Fallback to trip start coordinates if driver position is not available
      final startLatLng = LatLng(
        _currentTrip.startCoordinates![0],
        _currentTrip.startCoordinates![1],
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(startLatLng, 16),
      );
    }
  }

  void centerOnDriver() {
    if (_driverPosition.value != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_driverPosition.value!, 16),
      );
    } else if (_currentTrip.startCoordinates != null &&
        _mapController != null) {
      // Fallback to trip start coordinates if driver position is not available
      final startLatLng = LatLng(
        _currentTrip.startCoordinates![0],
        _currentTrip.startCoordinates![1],
      );
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(startLatLng, 16),
      );
    }
  }

  void toggleLocationTracking() {
    _isTrackingLocation = !_isTrackingLocation;
    if (_isTrackingLocation) {
      followDriver();
    }
  }

  // Calculate bearing between two points (for car rotation)
  double _calculateBearing(LatLng startPoint, LatLng endPoint) {
    final double startLat = _toRadians(startPoint.latitude);
    final double startLng = _toRadians(startPoint.longitude);
    final double endLat = _toRadians(endPoint.latitude);
    final double endLng = _toRadians(endPoint.longitude);

    final double deltaLng = endLng - startLng;

    final double y = math.sin(deltaLng) * math.cos(endLat);
    final double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(deltaLng);

    final double bearing = math.atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);
  double _toDegrees(double radians) => radians * (180.0 / math.pi);

  // Update trip data and refresh map
  void updateTripData(CurrentTrip newTripData) {
    _currentTrip = newTripData;
    _createMarkers();
    _createPolylines();
  }

  // Stop location tracking
  void stopLocationTracking() {
    _locationSubscription?.cancel();
    _isTrackingLocation = false;
  }

  // Get current driver location
  LatLng? getCurrentDriverLocation() {
    return _driverPosition.value;
  }

  // Get current zone ID
  String getCurrentZoneId() {
    try {
      if (Get.isRegistered<LocationController>()) {
        return Get.find<LocationController>().zoneID;
      }
    } catch (e) {
      debugPrint('Error getting zone ID: $e');
    }
    return '';
  }

  // Check if driver is near a specific location
  bool isDriverNearLocation(LatLng location, {double radiusInMeters = 100}) {
    if (_driverPosition.value == null) return false;

    double distance = Geolocator.distanceBetween(
      _driverPosition.value!.latitude,
      _driverPosition.value!.longitude,
      location.latitude,
      location.longitude,
    );

    return distance <= radiusInMeters;
  }

  // Initialize zone if not already set
  Future<void> initializeZone() async {
    try {
      if (!Get.isRegistered<LocationController>()) {
        debugPrint('LocationController not available for zone initialization');
        return;
      }

      if (Get.find<LocationController>().zoneID.isEmpty) {
        await Get.find<LocationController>().getZone(
          _driverPosition.value?.latitude.toString() ?? '0',
          _driverPosition.value?.longitude.toString() ?? '0',
          false,
        );
      }
    } catch (e) {
      debugPrint('Error initializing zone: $e');
    }
  }

  // Refresh zone for current location
  Future<void> refreshZone() async {
    try {
      if (!Get.isRegistered<LocationController>()) {
        debugPrint('LocationController not available for zone refresh');
        return;
      }

      if (_driverPosition.value != null) {
        await Get.find<LocationController>().getZone(
          _driverPosition.value!.latitude.toString(),
          _driverPosition.value!.longitude.toString(),
          false,
        );
      }
    } catch (e) {
      debugPrint('Error refreshing zone: $e');
    }
  }

  // Helper methods for UI
  Color getTripStatusColor() {
    switch (_currentTrip.tripStatus?.toLowerCase()) {
      case 'ongoing':
        return Colors.green;
      case 'scheduled':
        return Colors.purple;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String getTripStatusText() {
    switch (_currentTrip.tripStatus?.toLowerCase()) {
      case 'ongoing':
        return 'ongoing'.tr;
      case 'scheduled':
        return 'scheduled'.tr;
      case 'completed':
        return 'completed'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  // Getters for trip data
  // Proximity tracking methods
  void _startProximityChecking() {
    _proximityCheckTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkForNearbyPassengers();
    });
  }

  void _checkForNearbyPassengers() {
    if (_driverPosition.value == null ||
        _currentTrip.acceptedPassengers == null) {
      return;
    }

    List<AcceptedPassenger> nearby = [];

    for (AcceptedPassenger passenger in _currentTrip.acceptedPassengers!) {
      // Skip if passenger is already picked up
      if (passenger.status == 'picked_up' || passenger.status == 'completed') {
        continue;
      }

      // Check if passenger has pickup coordinates
      if (passenger.pickupCoordinates?.lat != null &&
          passenger.pickupCoordinates?.lng != null) {
        double distance = Geolocator.distanceBetween(
          _driverPosition.value!.latitude,
          _driverPosition.value!.longitude,
          passenger.pickupCoordinates!.lat!,
          passenger.pickupCoordinates!.lng!,
        );

        if (distance <= _proximityRadius) {
          nearby.add(passenger);
        }
      }
    }

    // Update nearby passengers list
    _nearbyPassengers.value = nearby;

    // Show dialog if there are nearby passengers and no dialog is currently showing
    if (nearby.isNotEmpty && !_isProximityDialogShowing.value) {
      _showProximityDialog(nearby.first);
    }
  }

  void _showProximityDialog(AcceptedPassenger passenger) {
    _isProximityDialogShowing.value = true;

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue),
            SizedBox(width: 8),
            Text('مستخدم قريب', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Passenger info card
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${passenger.passengerName ?? 'مستخدم'}',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    _buildInfoRow(Icons.phone, 'الهاتف',
                        'غير متوفر'), // passengerPhone is not available in new API structure
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.location_on, 'العنوان',
                        '${passenger.pickupAddress ?? 'غير متوفر'}'),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.event_seat, 'عدد المقاعد',
                        '${passenger.seatsCount ?? 1}'),
                    SizedBox(height: 8),
                    _buildInfoRow(Icons.attach_money, 'السعر',
                        '${passenger.fare?.toStringAsFixed(2) ?? '0'} ريال'),
                    if (passenger.otp != null) ...[
                      SizedBox(height: 8),
                      _buildInfoRow(
                          Icons.security, 'رمز التحقق', '${passenger.otp}',
                          isOtp: true),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Warning message
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange, size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'أنت على بعد 100 متر من موقع الاستلام. تأكد من هوية المستخدم قبل الاستلام.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _isProximityDialogShowing.value = false;
              Get.back();
            },
            child: Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () => pickupPassenger(passenger),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            icon: Icon(Icons.check_circle, size: 18),
            label: Text('استلام المستخدم'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  // Helper method for building info rows in dialog
  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isOtp = false}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: isOtp ? Colors.blue : Colors.grey.shade600),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              color: isOtp ? Colors.blue : Colors.black87,
              fontWeight: isOtp ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // Public method to show proximity dialog
  void showProximityDialog(AcceptedPassenger passenger) {
    _showProximityDialog(passenger);
  }

  // Getters for proximity data
  List<AcceptedPassenger> get nearbyPassengers => _nearbyPassengers;
  bool get isProximityDialogShowing => _isProximityDialogShowing.value;

  @override
  void onClose() {
    stopLocationTracking();
    _proximityCheckTimer?.cancel();
    _mapController?.dispose();
    super.onClose();
  }
}
