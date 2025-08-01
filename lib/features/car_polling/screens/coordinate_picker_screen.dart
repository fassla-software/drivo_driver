import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../../../common_widgets/app_bar_widget.dart';
import '../../../features/location/controllers/location_controller.dart';
import '../../../theme/theme_controller.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';

class CoordinatePickerScreen extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;

  const CoordinatePickerScreen({
    super.key,
    required this.title,
    this.initialPosition,
  });

  @override
  State<CoordinatePickerScreen> createState() => _CoordinatePickerScreenState();
}

class _CoordinatePickerScreenState extends State<CoordinatePickerScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedLocationName;
  Timer? _searchDebounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;

  static const String _googlePlacesApiKey =
      'AIzaSyBEBg6ItImxrxhsGbv7G9KNyvy1gr2MGwo';

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounceTimer?.cancel();
    super.dispose();
  }

  void _initializeMap() async {
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
      _addMarker(_selectedPosition!);
    } else {
      try {
        Position position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _addMarker(_selectedPosition!);
      } catch (e) {
        _selectedPosition = Get.find<LocationController>().initialPosition;
        _addMarker(_selectedPosition!);
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  void _addMarker(LatLng position, {String? locationName}) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('selected_location'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: locationName ?? 'Selected Location',
          snippet:
              '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
        ),
      ),
    );
    if (locationName != null) {
      _selectedLocationName = locationName;
    }
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _selectedLocationName = null;
      _addMarker(position);
      _searchController.clear();
      _showResults = false;
    });
  }

  void _confirmSelection() {
    if (_selectedPosition != null) {
      // استخدم Navigator مباشرة بدلاً من Get.back لتجنب أي منطق داخلي في GetX يسبب الخطأ
      Navigator.of(context).pop({
        'coordinates': _selectedPosition,
        'name': _selectedLocationName,
      });
    }
  }

  void _searchLocation(String value) {
    final query = value.trim();
    if (query.isEmpty) {
      setState(() {
        _searchResults.clear();
        _showResults = false;
      });
      return;
    }
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
    try {
      LatLng? currentLocation;
      try {
        Position position = await Geolocator.getCurrentPosition();
        currentLocation = LatLng(position.latitude, position.longitude);
      } catch (e) {
        currentLocation = Get.find<LocationController>().initialPosition;
      }
      final String url =
          'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=${Uri.encodeComponent(query)}'
          '&location=${currentLocation.latitude},${currentLocation.longitude}'
          '&radius=50000'
          '&key=$_googlePlacesApiKey';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          List<Map<String, dynamic>> places = [];
          for (var result in data['results']) {
            if (result['geometry'] != null &&
                result['geometry']['location'] != null) {
              places.add({
                'name': result['name'] ?? 'Unknown Place',
                'address': result['formatted_address'] ?? 'Unknown Address',
                'lat': result['geometry']['location']['lat'].toDouble(),
                'lng': result['geometry']['location']['lng'].toDouble(),
                'types': result['types'] ?? [],
                'rating': result['rating']?.toDouble(),
              });
            }
          }
          setState(() {
            _searchResults = places.take(10).toList();
            _isSearching = false;
            _showResults = true;
          });
        } else {
          setState(() {
            _searchResults = [];
            _isSearching = false;
            _showResults = true;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _isSearching = false;
          _showResults = true;
        });
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = true;
      });
    }
  }

  void _onResultTap(Map<String, dynamic> result) {
    LatLng position = LatLng(result['lat'], result['lng']);
    setState(() {
      _selectedPosition = position;
      _addMarker(position, locationName: result['name']);
      _searchController.text = result['name'];
      _showResults = false;
      _selectedLocationName = result['name'];
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(position, 16),
    );
    FocusScope.of(context).unfocus();
  }

  IconData _getPlaceIcon(List<dynamic>? types) {
    if (types == null || types.isEmpty) return Icons.location_on;
    String primaryType = types.first.toString();
    switch (primaryType) {
      case 'airport':
        return Icons.flight;
      case 'hospital':
        return Icons.local_hospital;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'restaurant':
        return Icons.restaurant;
      case 'shopping_mall':
        return Icons.shopping_cart;
      case 'school':
      case 'university':
        return Icons.school;
      case 'bank':
        return Icons.account_balance;
      case 'mosque':
        return Icons.mosque;
      case 'church':
        return Icons.church;
      case 'park':
        return Icons.park;
      case 'tourist_attraction':
        return Icons.attractions;
      case 'lodging':
        return Icons.hotel;
      default:
        return Icons.place;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: widget.title,
        showBackButton: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Google Map
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _selectedPosition ??
                        Get.find<LocationController>().initialPosition,
                    zoom: 16,
                  ),
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTap,
                  markers: _markers,
                  style: Get.isDarkMode
                      ? Get.find<ThemeController>().darkMap
                      : Get.find<ThemeController>().lightMap,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: true,
                ),
                // Search Field and Results
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(
                              Dimensions.paddingSizeDefault),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Theme.of(context).hintColor),
                            const SizedBox(width: Dimensions.paddingSizeSmall),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                decoration: InputDecoration(
                                  hintText: 'search_for_location'.tr,
                                  border: InputBorder.none,
                                  hintStyle: textRegular.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                                onChanged: _searchLocation,
                                onTap: () {
                                  setState(() {
                                    _showResults =
                                        _searchController.text.isNotEmpty;
                                  });
                                },
                              ),
                            ),
                            if (_isSearching)
                              Container(
                                padding: const EdgeInsets.all(8),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              )
                            else if (_searchController.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _searchController.clear();
                                    _searchResults.clear();
                                    _showResults = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (_showResults)
                        Container(
                          constraints: const BoxConstraints(maxHeight: 300),
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(
                                Dimensions.paddingSizeDefault),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _isSearching
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : _searchResults.isEmpty
                                  ? Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        'no_locations_found_for_search'.tr,
                                        style: textRegular,
                                      ),
                                    )
                                  : ListView.builder(
                                      shrinkWrap: true,
                                      itemCount: _searchResults.length,
                                      itemBuilder: (context, index) {
                                        final result = _searchResults[index];
                                        return ListTile(
                                          leading: Icon(
                                            _getPlaceIcon(result['types']),
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          title: Text(result['name'],
                                              style: textMedium),
                                          subtitle: Text(result['address'],
                                              style: textRegular.copyWith(
                                                  color: Theme.of(context)
                                                      .hintColor)),
                                          onTap: () => _onResultTap(result),
                                        );
                                      },
                                    ),
                        ),
                    ],
                  ),
                ),
                // Instructions Banner
                if (!_showResults && !_isSearching)
                  Positioned(
                    top: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius:
                            BorderRadius.circular(Dimensions.paddingSizeSmall),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: Dimensions.paddingSizeSmall),
                          Expanded(
                            child: Text(
                              'tap_on_map_to_select_location'.tr,
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Selected Coordinates Display
                if (_selectedPosition != null)
                  Positioned(
                    bottom: 80,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeDefault),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius:
                            BorderRadius.circular(Dimensions.paddingSizeSmall),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _selectedLocationName ?? 'selected_coordinates'.tr,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(
                              height: Dimensions.paddingSizeExtraSmall),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Theme.of(context).hintColor),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}',
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on,
                                  size: 16, color: Theme.of(context).hintColor),
                              const SizedBox(
                                  width: Dimensions.paddingSizeExtraSmall),
                              Text(
                                'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}',
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                // Confirm Button
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: ElevatedButton(
                    onPressed:
                        _selectedPosition != null ? _confirmSelection : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(Dimensions.paddingSizeSmall),
                      ),
                    ),
                    child: Text(
                      'confirm_location'.tr,
                      style: textMedium.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
