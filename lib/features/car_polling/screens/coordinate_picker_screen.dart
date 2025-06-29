import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  bool _showSearchField = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedLocationName;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _initializeMap() async {
    // Set initial position
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
      _addMarker(_selectedPosition!);
    } else {
      // Try to get current location
      try {
        Position position = await Geolocator.getCurrentPosition();
        _selectedPosition = LatLng(position.latitude, position.longitude);
        _addMarker(_selectedPosition!);
      } catch (e) {
        // Use default location if unable to get current location
        _selectedPosition = Get.find<LocationController>().initialPosition;
        _addMarker(_selectedPosition!);
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedPosition = position;
      _selectedLocationName = null;
      _addMarker(position);
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

  void _confirmSelection() {
    if (_selectedPosition != null) {
      Get.back(result: {
        'coordinates': _selectedPosition,
        'name': _selectedLocationName,
      });
    }
  }

  void _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Position position = await Geolocator.getCurrentPosition();
      LatLng currentPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _selectedPosition = currentPosition;
        _selectedLocationName = null;
        _addMarker(currentPosition);
        _isLoading = false;
      });

      // Move camera to current location
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentPosition, 16),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'unable_to_get_current_location'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _toggleSearch() {
    setState(() {
      _showSearchField = !_showSearchField;
      if (_showSearchField) {
        _searchFocusNode.requestFocus();
      } else {
        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    });
  }

  void _searchLocation() async {
    if (_searchController.text.trim().isEmpty) return;

    // For demo purposes, we'll simulate search results
    // In a real app, you would integrate with Google Places API
    List<Map<String, dynamic>> searchResults =
        _getSearchResults(_searchController.text.trim());

    if (searchResults.isNotEmpty) {
      _showSearchResults(searchResults);
    } else {
      Get.showSnackbar(GetSnackBar(
        title: 'no_results'.tr,
        message: 'no_locations_found_for_search'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.orange,
      ));
    }
  }

  List<Map<String, dynamic>> _getSearchResults(String query) {
    // Demo search results - replace with actual Google Places API integration
    List<Map<String, dynamic>> demoResults = [
      {
        'name': 'Cairo International Airport',
        'address': 'Cairo, Egypt',
        'lat': 30.1219,
        'lng': 31.4056,
      },
      {
        'name': 'Tahrir Square',
        'address': 'Downtown Cairo, Egypt',
        'lat': 30.0444,
        'lng': 31.2357,
      },
      {
        'name': 'Giza Pyramids',
        'address': 'Giza, Egypt',
        'lat': 29.9792,
        'lng': 31.1342,
      },
      {
        'name': 'Alexandria Corniche',
        'address': 'Alexandria, Egypt',
        'lat': 31.2001,
        'lng': 29.9187,
      },
      {
        'name': 'New Administrative Capital',
        'address': 'New Cairo, Egypt',
        'lat': 30.0131,
        'lng': 31.4914,
      },
    ];

    return demoResults
        .where((result) =>
            result['name'].toLowerCase().contains(query.toLowerCase()) ||
            result['address'].toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  void _showSearchResults(List<Map<String, dynamic>> results) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Dimensions.paddingSizeLarge),
            topRight: Radius.circular(Dimensions.paddingSizeLarge),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: Dimensions.paddingSizeSmall),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
              child: Row(
                children: [
                  Icon(Icons.search, color: Theme.of(context).primaryColor),
                  const SizedBox(width: Dimensions.paddingSizeSmall),
                  Text(
                    'search_results'.tr,
                    style: textBold.copyWith(
                      fontSize: Dimensions.fontSizeExtraLarge,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ),

            // Results list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeLarge),
                itemCount: results.length,
                itemBuilder: (context, index) {
                  final result = results[index];
                  return _buildSearchResultItem(result);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResultItem(Map<String, dynamic> result) {
    return InkWell(
      onTap: () {
        LatLng position = LatLng(result['lat'], result['lng']);
        setState(() {
          _selectedPosition = position;
          _addMarker(position, locationName: result['name']);
        });

        // Move camera to selected location
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(position, 16),
        );

        // Close search results
        Navigator.pop(context);
        _toggleSearch();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['name'],
                    style: textMedium.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['address'],
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Theme.of(context).hintColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
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

                // Search Field (Animated)
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  top: _showSearchField ? 16 : -80,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeDefault),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius:
                          BorderRadius.circular(Dimensions.paddingSizeDefault),
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
                        Icon(Icons.search, color: Theme.of(context).hintColor),
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
                            onSubmitted: (_) => _searchLocation(),
                          ),
                        ),
                        IconButton(
                          onPressed: _searchLocation,
                          icon: Icon(
                            Icons.send,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Instructions Banner
                if (!_showSearchField)
                  Positioned(
                    top: 16,
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

                // Action Buttons
                Positioned(
                  right: 16,
                  bottom: 200,
                  child: Column(
                    children: [
                      // Search Button
                      FloatingActionButton(
                        heroTag: "search",
                        mini: true,
                        onPressed: _toggleSearch,
                        backgroundColor: _showSearchField
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).primaryColor,
                        child: Icon(
                          _showSearchField ? Icons.close : Icons.search,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeSmall),

                      // Current Location Button
                      FloatingActionButton(
                        heroTag: "location",
                        mini: true,
                        onPressed: _getCurrentLocation,
                        backgroundColor: Theme.of(context).primaryColor,
                        child:
                            const Icon(Icons.my_location, color: Colors.white),
                      ),
                    ],
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
