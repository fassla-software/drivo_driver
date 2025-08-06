import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../domain/models/simple_trip_model.dart';
import '../domain/models/passenger_coordinate_model.dart';

class CarpoolMainMapController extends GetxController {
  final SimpleTripModel carpoolTrip;

  CarpoolMainMapController({required this.carpoolTrip});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  GoogleMapController? _mapController;
  Position? _currentPosition;

  // Map data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _mainRoutePoints = [];
  List<LatLng> _passengerRoutePoints = [];
  List<LatLng> _polylineCoordinateList = []; // For car tracking on polyline
  bool _isFollowingDriver = false;
  double _sheetHeight = 300;
  bool _isTrafficEnable = false;

  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<LatLng> get mainRoutePoints => _mainRoutePoints;
  List<LatLng> get passengerRoutePoints => _passengerRoutePoints;
  List<LatLng> get polylineCoordinateList => _polylineCoordinateList;
  bool get isFollowingDriver => _isFollowingDriver;
  double get sheetHeight => _sheetHeight;
  bool get isTrafficEnable => _isTrafficEnable;
  GoogleMapController? get mapController => _mapController;

  LatLng get initialPosition {
    if (carpoolTrip.startCoordinates != null &&
        carpoolTrip.startCoordinates!.length >= 2) {
      return LatLng(
          carpoolTrip.startCoordinates![1], carpoolTrip.startCoordinates![0]);
    }
    return const LatLng(30.0444, 31.2357); // Cairo default
  }

  String get remainingDistance {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    return '5.2 km';
  }

  String get polylineSource {
    if (carpoolTrip.encodedPolyline != null &&
        carpoolTrip.encodedPolyline!.isNotEmpty) {
      return 'Trip Polyline (${carpoolTrip.encodedPolyline!.length} chars)';
    }
    return 'No polyline available';
  }

  String get estimatedTimeToDestination {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    return '15 min';
  }

  // Calculate bearing between two points like in RiderMapController
  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * math.pi / 180;
    double startLng = start.longitude * math.pi / 180;
    double endLat = end.latitude * math.pi / 180;
    double endLng = end.longitude * math.pi / 180;

    double deltaLng = endLng - startLng;

    double y = math.sin(deltaLng) * math.cos(endLat);
    double x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(deltaLng);

    final double bearing = math.atan2(y, x);

    return (_toDegrees(bearing) + 360) % 360;
  }

  double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  double _toDegrees(double radians) => radians * (180.0 / math.pi);

  // Convert asset to Uint8List like in map_controller.dart
  Future<Uint8List> _convertAssetToUnit8List(String imagePath,
      {int width = 50}) async {
    ByteData data = await rootBundle.load(imagePath);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width);
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }

  // Get route from Google Directions API
  Future<List<LatLng>> _getRouteFromGoogleDirections(
      LatLng origin, LatLng destination) async {
    try {
      final url =
          Uri.parse('https://maps.googleapis.com/maps/api/directions/json?'
              'origin=${origin.latitude},${origin.longitude}'
              '&destination=${destination.latitude},${destination.longitude}'
              '&key=$googleMapsApiKey');

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final polyline = route['overview_polyline']['points'];

          // Decode polyline
          PolylinePoints polylinePoints = PolylinePoints();
          List<PointLatLng> result = polylinePoints.decodePolyline(polyline);

          return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
        }
      }

      return [];
    } catch (e) {
      print('=== Error in _getRouteFromGoogleDirections: $e ===');
      return [];
    }
  }

  // Google Maps Directions API key
  static const String googleMapsApiKey =
      'AIzaSyBEBg6ItImxrxhsGbv7G9KNyvy1gr2MGwo';

  /// Decode polyline
  List<LatLng> decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    print(
        '=== CarpoolMainMapController initialized for trip ID: ${carpoolTrip.id} ===');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  void setSheetHeight(double height, bool notify) {
    _sheetHeight = height;
    if (notify) update();
  }

  void toggleTrafficView() {
    _isTrafficEnable = !_isTrafficEnable;
    update();
  }

  Future<void> initializeMap() async {
    try {
      print(
          '=== Initializing carpool main map for trip ID: ${carpoolTrip.id} ===');
      print('=== Trip data: ===');
      print('=== Start coordinates: ${carpoolTrip.startCoordinates} ===');
      print('=== End coordinates: ${carpoolTrip.endCoordinates} ===');
      print(
          '=== Passenger coordinates count: ${carpoolTrip.passengerCoordinates?.length ?? 0} ===');
      print('=== Passengers count: ${carpoolTrip.passengers?.length ?? 0} ===');

      _isLoading = true;
      update();

      // Get current location first
      await _getCurrentLocation();

      // Create markers
      await _createMarkers();

      // Load route data first
      await _loadMainRoute();

      // Create polylines after loading route
      _createPolylines();

      _isLoading = false;
      update();

      // Fit markers on map
      _fitMarkersOnMap();
    } catch (e) {
      print('=== Error initializing carpool main map: $e ===');
      _isLoading = false;
      update();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('=== Location services are disabled ===');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('=== Location permissions are denied ===');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('=== Location permissions are permanently denied ===');
        return;
      }

      _currentPosition = await Geolocator.getCurrentPosition();
      print(
          '=== Current position: ${_currentPosition!.latitude}, ${_currentPosition!.longitude} ===');

      // Update polylines after getting current position
      _updateCurrentToStartPolyline();
    } catch (e) {
      print('=== Error getting current location: $e ===');
    }
  }

  Future<void> _createMarkers() async {
    _markers.clear();

    // Get car icon like in map_controller.dart
    Uint8List carIcon;
    try {
      carIcon = await _convertAssetToUnit8List('assets/image/car_icon_top.png',
          width: 50);
    } catch (e) {
      // Fallback to default marker
      carIcon = await _convertAssetToUnit8List(
          'assets/image/map_location_icon.png',
          width: 50);
    }

    // Add car marker at current position if available
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId("car"),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          rotation: _currentPosition!.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(carIcon),
        ),
      );
    } else {
      // Add a placeholder car marker at start position if no current position
      if (carpoolTrip.startCoordinates != null &&
          carpoolTrip.startCoordinates!.length >= 2) {
        _markers.add(
          Marker(
            markerId: const MarkerId("car"),
            position: LatLng(carpoolTrip.startCoordinates![1],
                carpoolTrip.startCoordinates![0]),
            rotation: 0,
            draggable: false,
            zIndex: 2,
            flat: true,
            anchor: const Offset(0.5, 0.5),
            icon: BitmapDescriptor.fromBytes(carIcon),
          ),
        );
      }
    }

    // Start marker
    if (carpoolTrip.startCoordinates != null &&
        carpoolTrip.startCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(carpoolTrip.startCoordinates![1],
              carpoolTrip.startCoordinates![0]),
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: carpoolTrip.startAddress ?? 'Trip start location',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // End marker
    if (carpoolTrip.endCoordinates != null &&
        carpoolTrip.endCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
              carpoolTrip.endCoordinates![1], carpoolTrip.endCoordinates![0]),
          infoWindow: InfoWindow(
            title: 'End',
            snippet: carpoolTrip.endAddress ?? 'Trip end location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Passenger pickup markers only
    print('=== Creating passenger pickup markers ===');
    print(
        '=== Passenger coordinates count: ${carpoolTrip.passengerCoordinates?.length ?? 0} ===');

    if (carpoolTrip.passengerCoordinates != null) {
      for (int i = 0; i < carpoolTrip.passengerCoordinates!.length; i++) {
        final passengerCoord = carpoolTrip.passengerCoordinates![i];

        // Only show pickup coordinates
        if (passengerCoord.isPickup && passengerCoord.hasValidCoordinates) {
          print(
              '=== Passenger pickup coord $i: coords=${passengerCoord.coordinates} ===');

          final latLng = LatLng(
            passengerCoord.coordinates![0], // longitude
            passengerCoord.coordinates![1], // latitude
          );

          print(
              '=== Adding pickup marker: ${latLng.latitude}, ${latLng.longitude} ===');

          // Find passenger data for this pickup
          String passengerInfo = 'Unknown Passenger';
          if (carpoolTrip.passengers != null) {
            for (final passenger in carpoolTrip.passengers!) {
              if (passenger.carpoolTripId == passengerCoord.passengerId) {
                passengerInfo =
                    '${passenger.name ?? 'Unknown'} (${passenger.seatsCount ?? 1} seats)';
                break;
              }
            }
          }

          _markers.add(
            Marker(
              markerId:
                  MarkerId('passenger_pickup_${passengerCoord.passengerId}'),
              position: latLng,
              infoWindow: InfoWindow(
                title: 'Pickup - $passengerInfo',
                snippet:
                    '${passengerCoord.address ?? 'Passenger pickup location'}\nStatus: ${_getPassengerStatus(passengerCoord.passengerId ?? '')}',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueYellow),
            ),
          );
        }
      }
    }

    print('=== Total markers created: ${_markers.length} ===');
    update();
  }

  void _createPolylines() {
    // Don't clear polylines - keep the main route polyline
    // _polylines.clear();
    update();
  }

  void _updateCurrentToStartPolyline() async {
    print('=== Updating current to start polyline ===');

    // Add polyline from current position to start point if available
    if (_currentPosition != null &&
        carpoolTrip.startCoordinates != null &&
        carpoolTrip.startCoordinates!.length >= 2) {
      // Remove existing current_to_start polyline if exists
      _polylines.removeWhere((polyline) =>
          polyline.polylineId == const PolylineId('current_to_start'));

      final startPoint = LatLng(
          carpoolTrip.startCoordinates![1], carpoolTrip.startCoordinates![0]);
      final currentPoint =
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

      print(
          '=== Current point: ${currentPoint.latitude.toStringAsFixed(4)}, ${currentPoint.longitude.toStringAsFixed(4)} ===');
      print(
          '=== Start point: ${startPoint.latitude.toStringAsFixed(4)}, ${startPoint.longitude.toStringAsFixed(4)} ===');

      // Only add if current position is different from start point
      if (currentPoint.latitude != startPoint.latitude ||
          currentPoint.longitude != startPoint.longitude) {
        // Get route from Google Directions API
        try {
          final routePoints =
              await _getRouteFromGoogleDirections(currentPoint, startPoint);
          if (routePoints.isNotEmpty) {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('current_to_start'),
                points: routePoints,
                color: Colors.orange,
                width: 3,
                geodesic: true,
              ),
            );
            print(
                '=== Current to start polyline added successfully with ${routePoints.length} points ===');
          } else {
            // Fallback to direct line if API fails
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('current_to_start'),
                points: [currentPoint, startPoint],
                color: Colors.orange,
                width: 3,
                geodesic: true,
              ),
            );
            print('=== Fallback: Direct line polyline added ===');
          }
        } catch (e) {
          print('=== Error getting route from Google Directions: $e ===');
          // Fallback to direct line
          _polylines.add(
            Polyline(
              polylineId: const PolylineId('current_to_start'),
              points: [currentPoint, startPoint],
              color: Colors.orange,
              width: 3,
              geodesic: true,
            ),
          );
          print('=== Fallback: Direct line polyline added after error ===');
        }
      } else {
        print(
            '=== Current position is same as start point, no polyline needed ===');
      }
    } else {
      print('=== Cannot create current to start polyline: missing data ===');
      print(
          '=== Current position: ${_currentPosition != null ? 'available' : 'null'} ===');
      print(
          '=== Start coordinates: ${carpoolTrip.startCoordinates != null ? 'available' : 'null'} ===');
    }

    print('=== Total polylines after update: ${_polylines.length} ===');
    update();
  }

  Future<void> _loadMainRoute() async {
    try {
      print('=== Loading main route ===');
      print('=== Encoded polyline: ${carpoolTrip.encodedPolyline} ===');

      // Use encoded polyline from the server (static route for carpool trips)
      if (carpoolTrip.encodedPolyline != null &&
          carpoolTrip.encodedPolyline!.isNotEmpty) {
        print('=== Using encoded polyline from server ===');
        print(
            '=== Encoded polyline length: ${carpoolTrip.encodedPolyline!.length} characters ===');
        _mainRoutePoints = decodePolyline(carpoolTrip.encodedPolyline!);
        _polylineCoordinateList =
            List.from(_mainRoutePoints); // Copy for car tracking
        _updateMainRoutePolyline();
        print('=== Decoded polyline points: ${_mainRoutePoints.length} ===');
        print('=== Polyline source: Server (static carpool route) ===');
      } else {
        print('=== No encoded polyline available from server ===');
        print('=== No polyline will be drawn ===');
      }
    } catch (e) {
      print('=== Error loading main route: $e ===');
    }
  }

  void _updateMainRoutePolyline() {
    print('=== Updating main route polyline ===');
    print('=== Main route points count: ${_mainRoutePoints.length} ===');

    _polylines.removeWhere(
        (polyline) => polyline.polylineId == const PolylineId('main_route'));

    if (_mainRoutePoints.isNotEmpty) {
      print('=== Creating polyline with ${_mainRoutePoints.length} points ===');
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('main_route'),
          points: _mainRoutePoints,
          color: Colors.blue,
          width: 5,
          geodesic: true,
        ),
      );
      print('=== Main route polyline added successfully ===');
      print(
          '=== Polyline points: ${_mainRoutePoints.take(3).map((p) => '${p.latitude.toStringAsFixed(4)}, ${p.longitude.toStringAsFixed(4)}').join(' -> ')} ===');
    } else {
      print('=== No route points to create polyline ===');
    }

    print('=== Total polylines: ${_polylines.length} ===');
    update();
  }

  void _fitMarkersOnMap() {
    if (_mapController != null && _markers.isNotEmpty) {
      try {
        LatLngBounds bounds = _getBoundsForMarkers();
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 50.0),
        );
      } catch (e) {
        print('=== Error fitting markers: $e ===');
      }
    }
  }

  LatLngBounds _getBoundsForMarkers() {
    double? minLat, maxLat, minLng, maxLng;

    for (Marker marker in _markers) {
      if (minLat == null || marker.position.latitude < minLat) {
        minLat = marker.position.latitude;
      }
      if (maxLat == null || marker.position.latitude > maxLat) {
        maxLat = marker.position.latitude;
      }
      if (minLng == null || marker.position.longitude < minLng) {
        minLng = marker.position.longitude;
      }
      if (maxLng == null || marker.position.longitude > maxLng) {
        maxLng = marker.position.longitude;
      }
    }

    return LatLngBounds(
      southwest: LatLng(minLat ?? 0, minLng ?? 0),
      northeast: LatLng(maxLat ?? 0, maxLng ?? 0),
    );
  }

  void fitMarkersOnMap() {
    _fitMarkersOnMap();
  }

  void onCameraMove() {
    if (_isFollowingDriver) {
      _isFollowingDriver = false;
      update();
    }
  }

  void toggleFollowDriver() {
    _isFollowingDriver = !_isFollowingDriver;
    update();
  }

  void returnToDriver() {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  void openInGoogleMaps() async {
    if (carpoolTrip.startCoordinates != null &&
        carpoolTrip.endCoordinates != null) {
      final startLat = carpoolTrip.startCoordinates![1];
      final startLng = carpoolTrip.startCoordinates![0];
      final endLat = carpoolTrip.endCoordinates![1];
      final endLng = carpoolTrip.endCoordinates![0];

      final url =
          'https://www.google.com/maps/dir/?api=1&origin=$startLat,$startLng&destination=$endLat,$endLng&travelmode=driving';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      }
    }
  }

  Future<void> myCurrentLocation() async {
    if (_currentPosition != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        ),
      );
    }
  }

  String _getPassengerStatus(String passengerId) {
    if (carpoolTrip.passengers != null) {
      for (final passenger in carpoolTrip.passengers!) {
        if (passenger.carpoolTripId == passengerId) {
          return passenger.status ?? 'Unknown';
        }
      }
    }
    return 'Unknown';
  }

  // Add car marker like in original map screen
  void addCarMarker(LatLng position, double heading) {
    _markers.removeWhere((marker) => marker.markerId == const MarkerId("car"));

    _markers.add(
      Marker(
        markerId: const MarkerId("car"),
        position: position,
        rotation: heading,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );
    update();
  }

  // Update car position like in original map screen
  void updateCarPosition(LatLng newPosition, double heading) async {
    // Remove existing car marker
    _markers.removeWhere((marker) => marker.markerId == const MarkerId("car"));

    // Get car icon like in map_controller.dart
    Uint8List carIcon;
    try {
      carIcon = await _convertAssetToUnit8List('assets/image/car_icon_top.png',
          width: 50);
    } catch (e) {
      // Fallback to default marker
      carIcon = await _convertAssetToUnit8List(
          'assets/image/map_location_icon.png',
          width: 50);
    }

    // Add car marker at new position
    _markers.add(
      Marker(
        markerId: const MarkerId("car"),
        position: newPosition,
        rotation: heading,
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(carIcon),
      ),
    );

    // Update polylines with new position
    _updateCurrentToStartPolyline();

    // Move camera to follow car if following is enabled
    if (_isFollowingDriver && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            bearing: heading,
            target: newPosition,
            tilt: 0,
            zoom: 16,
          ),
        ),
      );
    }

    update();
  }

  // Start location tracking like in original map screen
  void startLocationTracking() {
    if (_currentPosition != null) {
      // Update car marker position
      _markers
          .removeWhere((marker) => marker.markerId == const MarkerId("car"));
      _markers.add(
        Marker(
          markerId: const MarkerId("car"),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          rotation: _currentPosition!.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      update();
    }
  }

  // Update marker and circle like in RiderMapController
  void updateMarkerAndCircle(LatLng? latLong) async {
    _markers.removeWhere((marker) => marker.markerId.value == "car");

    // Get car icon like in map_controller.dart
    Uint8List carIcon;
    try {
      carIcon = await _convertAssetToUnit8List('assets/image/car_icon_top.png',
          width: 50);
    } catch (e) {
      // Fallback to default marker
      carIcon = await _convertAssetToUnit8List(
          'assets/image/map_location_icon.png',
          width: 50);
    }

    if (_polylineCoordinateList.isNotEmpty) {
      _markers.add(Marker(
        markerId: const MarkerId("car"),
        position: latLong ?? _polylineCoordinateList.first,
        rotation: _calculateBearing(
            _polylineCoordinateList.first,
            _polylineCoordinateList.length > 1
                ? _polylineCoordinateList[1]
                : _polylineCoordinateList.last),
        draggable: false,
        zIndex: 2,
        flat: true,
        anchor: const Offset(0.5, 0.5),
        icon: BitmapDescriptor.fromBytes(carIcon),
      ));
    }

    // Update polylines with new position
    _updateCurrentToStartPolyline();

    update();
  }

  // Set markers initial position like in original map screen
  void setMarkersInitialPosition() {
    if (_currentPosition != null) {
      // Update car marker position
      _markers
          .removeWhere((marker) => marker.markerId == const MarkerId("car"));
      _markers.add(
        Marker(
          markerId: const MarkerId("car"),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          rotation: _currentPosition!.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
      update();
    }
  }
}
