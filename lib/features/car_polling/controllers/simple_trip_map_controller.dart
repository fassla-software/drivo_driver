import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

import '../domain/models/simple_trip_model.dart';
import '../domain/models/passenger_coordinate_model.dart';

class SimpleTripMapController extends GetxController {
  final SimpleTripModel trip;

  SimpleTripMapController({required this.trip});

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  GoogleMapController? _mapController;
  Position? _currentPosition;

  // Map data
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  List<LatLng> _mainRoutePoints = [];
  List<LatLng> _driverToStartRoute = [];
  List<LatLng> _passengerRoutePoints = [];
  bool _isFollowingDriver = false;

  // Getters
  Set<Marker> get markers => _markers;
  Set<Polyline> get polylines => _polylines;
  List<LatLng> get mainRoutePoints => _mainRoutePoints;
  List<LatLng> get driverToStartRoute => _driverToStartRoute;
  List<LatLng> get passengerRoutePoints => _passengerRoutePoints;
  bool get isFollowingDriver => _isFollowingDriver;

  LatLng get initialPosition {
    if (trip.startCoordinates != null && trip.startCoordinates!.length >= 2) {
      // API returns [longitude, latitude] but Google Maps expects (latitude, longitude)
      return LatLng(trip.startCoordinates![1], trip.startCoordinates![0]);
    }
    return const LatLng(30.0444, 31.2357); // Cairo default
  }

  String get remainingDistance {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    // Calculate distance logic here
    return '5.2 km';
  }

  String get estimatedTimeToDestination {
    if (_mainRoutePoints.isEmpty) return 'Calculating...';
    // Calculate ETA logic here
    return '15 min';
  }

  // أضف متغير لمفتاح Google Maps Directions API
  static const String googleMapsApiKey =
      'AIzaSyBEBg6ItImxrxhsGbv7G9KNyvy1gr2MGwo'; // ضع مفتاحك هنا

  /// جلب مسار القيادة الحقيقي من Google Directions API
  Future<List<LatLng>> getRoutePolyline(List<LatLng> points) async {
    if (points.length < 2) return points;
    final origin = '${points.first.latitude},${points.first.longitude}';
    final destination = '${points.last.latitude},${points.last.longitude}';
    String waypoints = '';
    if (points.length > 2) {
      waypoints = points
          .sublist(1, points.length - 1)
          .map((p) => '${p.latitude},${p.longitude}')
          .join('|');
    }
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$destination${waypoints.isNotEmpty ? '&waypoints=$waypoints' : ''}&key=$googleMapsApiKey&mode=driving';
    print('=== Directions API URL: $url ===');
    final response = await http.get(Uri.parse(url));
    final data = json.decode(response.body);
    if (data['routes'] != null && data['routes'].isNotEmpty) {
      final polyline = data['routes'][0]['overview_polyline']['points'];
      return decodePolyline(polyline);
    }
    print('=== Directions API error: ${data['status']} ===');
    return points;
  }

  /// فك تشفير polyline
  List<LatLng> decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((p) => LatLng(p.latitude, p.longitude)).toList();
  }

  @override
  void onInit() {
    super.onInit();
    print(
        '=== SimpleTripMapController initialized for trip ID: ${trip.id} ===');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void setMapController(GoogleMapController controller) {
    _mapController = controller;
  }

  Future<void> initializeMap() async {
    try {
      print('=== Initializing map for trip ID: ${trip.id} ===');
      print('=== Trip data: ===');
      print('=== Start coordinates: ${trip.startCoordinates} ===');
      print('=== End coordinates: ${trip.endCoordinates} ===');
      print(
          '=== Passenger coordinates count: ${trip.passengerCoordinates?.length ?? 0} ===');
      print('=== Passengers count: ${trip.passengers?.length ?? 0} ===');

      _isLoading = true;
      update();

      // Get current location
      await _getCurrentLocation();

      // Create markers
      _createMarkers();

      // Create polylines
      _createPolylines();

      // Load route data
      await _loadMainRoute();
      await _loadDriverToStartRoute();

      _isLoading = false;
      update();

      // Fit markers on map
      _fitMarkersOnMap();
    } catch (e) {
      print('=== Error initializing map: $e ===');
      _isLoading = false;
      update();
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }

      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      print(
          '=== Current position: ${_currentPosition?.latitude}, ${_currentPosition?.longitude} ===');
    } catch (e) {
      print('=== Error getting current location: $e ===');
    }
  }

  void _createMarkers() {
    _markers.clear();

    // Start marker
    if (trip.startCoordinates != null && trip.startCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: LatLng(
              trip.startCoordinates![1],
              trip.startCoordinates![
                  0]), // [longitude, latitude] -> (latitude, longitude)
          infoWindow: InfoWindow(
            title: 'Start',
            snippet: trip.startAddress ?? 'Start location',
          ),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );
    }

    // End marker
    if (trip.endCoordinates != null && trip.endCoordinates!.length >= 2) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: LatLng(
              trip.endCoordinates![1],
              trip.endCoordinates![
                  0]), // [longitude, latitude] -> (latitude, longitude)
          infoWindow: InfoWindow(
            title: 'End',
            snippet: trip.endAddress ?? 'End location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Driver marker
    if (_currentPosition != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('driver'),
          position:
              LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          infoWindow: const InfoWindow(
            title: 'Driver',
            snippet: 'Your current location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    }

    // Passenger markers
    print('=== Creating passenger markers ===');
    print(
        '=== Passenger coordinates count: ${trip.passengerCoordinates?.length ?? 0} ===');

    if (trip.passengerCoordinates != null) {
      for (int i = 0; i < trip.passengerCoordinates!.length; i++) {
        final passengerCoord = trip.passengerCoordinates![i];
        print(
            '=== Passenger coord $i: type=${passengerCoord.type}, coords=${passengerCoord.coordinates} ===');

        if (passengerCoord.hasValidCoordinates) {
          final latLng = LatLng(
            passengerCoord.coordinates![1], // latitude
            passengerCoord.coordinates![0], // longitude
          );

          print(
              '=== Adding passenger marker: ${latLng.latitude}, ${latLng.longitude} ===');

          _markers.add(
            Marker(
              markerId: MarkerId(
                  'passenger_${passengerCoord.passengerId}_${passengerCoord.type}'),
              position: latLng,
              infoWindow: InfoWindow(
                title: passengerCoord.isPickup ? 'Pickup' : 'Dropoff',
                snippet: passengerCoord.address ?? 'Passenger location',
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(
                passengerCoord.isPickup
                    ? BitmapDescriptor.hueYellow
                    : BitmapDescriptor.hueOrange,
              ),
            ),
          );
        }
      }
    }

    print('=== Total markers created: ${_markers.length} ===');

    update();
  }

  void _createPolylines() {
    _polylines.clear();
    update();
  }

  @override
  Future<void> _loadMainRoute() async {
    try {
      print('=== Loading main route ===');
      print('=== Start coordinates: ${trip.startCoordinates} ===');
      print('=== End coordinates: ${trip.endCoordinates} ===');
      print(
          '=== Passenger coordinates: ${trip.passengerCoordinates?.length ?? 0} ===');

      if (trip.startCoordinates != null &&
          trip.endCoordinates != null &&
          trip.startCoordinates!.length >= 2 &&
          trip.endCoordinates!.length >= 2) {
        // Start with trip start point
        List<LatLng> routePoints = [
          LatLng(
              trip.startCoordinates![1],
              trip.startCoordinates![
                  0]), // [longitude, latitude] -> (latitude, longitude)
        ];

        // Add passenger coordinates in order
        if (trip.passengerCoordinates != null &&
            trip.passengerCoordinates!.isNotEmpty) {
          print('=== Processing passenger coordinates ===');
          // Sort passenger coordinates by type (pickup first, then dropoff)
          final sortedCoordinates =
              List<PassengerCoordinateModel>.from(trip.passengerCoordinates!);
          sortedCoordinates.sort((a, b) {
            if (a.isPickup && b.isDropoff) return -1;
            if (a.isDropoff && b.isPickup) return 1;
            return 0;
          });
          print(
              '=== Sorted coordinates count: ${sortedCoordinates.length} ===');
          for (int i = 0; i < sortedCoordinates.length; i++) {
            final passengerCoord = sortedCoordinates[i];
            print(
                '=== Processing coord $i: type=${passengerCoord.type}, coords=${passengerCoord.coordinates} ===');
            if (passengerCoord.hasValidCoordinates) {
              final latLng = LatLng(
                passengerCoord.coordinates![1], // latitude
                passengerCoord.coordinates![0], // longitude
              );
              print(
                  '=== Adding route point: ${latLng.latitude}, ${latLng.longitude} ===');
              routePoints.add(latLng);
            }
          }
        }

        // End with trip end point
        routePoints.add(LatLng(
            trip.endCoordinates![1],
            trip.endCoordinates![
                0])); // [longitude, latitude] -> (latitude, longitude)

        // جلب المسار الحقيقي من Google Directions API
        _mainRoutePoints = await getRoutePolyline(routePoints);

        // Update polyline with route points
        _updateMainRoutePolyline();

        print('=== Main route points: ${_mainRoutePoints.length} points ===');
        for (int i = 0; i < _mainRoutePoints.length; i++) {
          print(
              '=== Point $i: ${_mainRoutePoints[i].latitude}, ${_mainRoutePoints[i].longitude} ===');
        }
      }
    } catch (e) {
      print('=== Error loading main route: $e ===');
    }
  }

  Future<void> _loadDriverToStartRoute() async {
    try {
      if (_currentPosition != null &&
          trip.startCoordinates != null &&
          trip.startCoordinates!.length >= 2) {
        // For now, create a simple route from driver to start
        _driverToStartRoute = [
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          LatLng(
              trip.startCoordinates![1],
              trip.startCoordinates![
                  0]), // [longitude, latitude] -> (latitude, longitude)
        ];

        // Update polylines
        _updateDriverToStartPolyline();
      }
    } catch (e) {
      print('=== Error loading driver to start route: $e ===');
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
      print('=== Polyline added successfully ===');
    } else {
      print('=== No route points to create polyline ===');
    }

    print('=== Total polylines: ${_polylines.length} ===');
    update();
  }

  void _updateDriverToStartPolyline() {
    _polylines.removeWhere((polyline) =>
        polyline.polylineId == const PolylineId('driver_to_start'));

    if (_driverToStartRoute.isNotEmpty) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('driver_to_start'),
          points: _driverToStartRoute,
          color: Colors.orange,
          width: 3,
        ),
      );
    }

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

    if (_isFollowingDriver && _currentPosition != null) {
      _animateToDriver();
    }
  }

  void _animateToDriver() {
    if (_mapController != null && _currentPosition != null) {
      try {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(
            LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          ),
        );
      } catch (e) {
        print('=== Error animating to driver: $e ===');
      }
    }
  }

  void returnToDriver() {
    _animateToDriver();
    Get.showSnackbar(GetSnackBar(
      title: 'info'.tr,
      message: 'returned_to_driver'.tr,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.blue,
    ));
  }

  Future<void> openInGoogleMaps() async {
    try {
      if (trip.startCoordinates != null &&
          trip.endCoordinates != null &&
          trip.startCoordinates!.length >= 2 &&
          trip.endCoordinates!.length >= 2) {
        String startCoords =
            '${trip.startCoordinates![1]},${trip.startCoordinates![0]}'; // [longitude, latitude] -> (latitude, longitude)
        String endCoords =
            '${trip.endCoordinates![1]},${trip.endCoordinates![0]}'; // [longitude, latitude] -> (latitude, longitude)

        String url = 'https://www.google.com/maps/dir/$startCoords/$endCoords';

        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(
            Uri.parse(url),
            mode: LaunchMode.externalApplication,
          );
        } else {
          throw Exception('Could not launch Google Maps');
        }
      } else {
        Get.showSnackbar(GetSnackBar(
          title: 'error'.tr,
          message: 'no_coordinates_available'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      print('=== Error opening Google Maps: $e ===');
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'failed_to_open_google_maps'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
    }
  }
}
