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
  bool _showSearchField = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String? _selectedLocationName;
  Timer? _searchDebounceTimer;
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, List<Map<String, dynamic>>> _searchCache = {};

  // Your API key from AndroidManifest.xml
  // This is safe since it's not committed to public repositories
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
    // Set initial position
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
      _addMarker(_selectedPosition!);
    } else {
      // Try to get current location
      try {
        Position position;

        // Try to get location with high accuracy first
        try {
          position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 8), // 8 second timeout for init
            ),
          );
        } catch (e) {
          // Fallback to medium accuracy if high accuracy fails
          position = await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 12), // 12 second timeout
            ),
          );
        }

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
      Position position;

      // Try to get location with high accuracy first
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10), // 10 second timeout
          ),
        );
      } catch (e) {
        // Fallback to medium accuracy if high accuracy fails
        position = await Geolocator.getCurrentPosition(
          locationSettings: LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 15), // 15 second timeout
          ),
        );
      }

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
        title: 'location_error'.tr,
        message: 'unable_to_get_current_location'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.orange,
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
        _searchResults.clear();
        _searchDebounceTimer?.cancel();
      }
    });
  }

  void _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Cancel previous search timer
    _searchDebounceTimer?.cancel();

    // Debounce search to avoid too many API calls
    _searchDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  void _performSearch(String query) async {
    if (query.length < 2) return;

    // Check cache first
    if (_searchCache.containsKey(query)) {
      setState(() {
        _searchResults = _searchCache[query]!;
      });
      if (_searchResults.isNotEmpty) {
        _showSearchResults(_searchResults);
      }
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      List<Map<String, dynamic>> results = await _getPlacesFromGoogleAPI(query);

      // Cache the results
      _searchCache[query] = results;

      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      if (results.isNotEmpty) {
        _showSearchResults(results);
      } else {
        Get.showSnackbar(GetSnackBar(
          title: 'no_results'.tr,
          message: 'no_locations_found_for_search'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ));
      }
    } catch (e) {
      setState(() {
        _isSearching = false;
      });

      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'search_failed_please_try_again'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));

      // Fallback to demo results if API fails
      List<Map<String, dynamic>> fallbackResults =
          _getFallbackSearchResults(query);
      if (fallbackResults.isNotEmpty) {
        _showSearchResults(fallbackResults);
      }
    }
  }

  Future<List<Map<String, dynamic>>> _getPlacesFromGoogleAPI(
      String query) async {
    try {
      // Get current location for better search results
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
                'place_id': result['place_id'] ?? '',
                'types': result['types'] ?? [],
                'rating': result['rating']?.toDouble(),
                'price_level': result['price_level'],
              });
            }
          }

          return places
              .take(10)
              .toList(); // Limit to 10 results for performance
        } else if (data['status'] == 'REQUEST_DENIED') {
          throw Exception(
              'API key invalid or Places API not enabled. Check your Google Cloud Console.');
        } else if (data['status'] == 'OVER_QUERY_LIMIT') {
          throw Exception('Query limit exceeded. Check your API usage limits.');
        } else if (data['status'] == 'ZERO_RESULTS') {
          return []; // Return empty list for no results
        } else {
          throw Exception('Places API error: ${data['status']}');
        }
      } else {
        throw Exception('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Google Places API Error: $e');
      throw e;
    }
  }

  List<Map<String, dynamic>> _getFallbackSearchResults(String query) {
    // Fallback search results when API fails
    List<Map<String, dynamic>> fallbackResults = [
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
      {
        'name': 'Hurghada Marina',
        'address': 'Hurghada, Egypt',
        'lat': 27.2579,
        'lng': 33.8116,
      },
      {
        'name': 'Sharm El Sheikh Airport',
        'address': 'Sharm El Sheikh, Egypt',
        'lat': 27.9773,
        'lng': 34.3950,
      },
    ];

    return fallbackResults
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
          color: Theme.of(context).cardColor,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPlaceIcon(result['types']),
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeDefault),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['name'],
                          style: textMedium.copyWith(
                            fontSize: Dimensions.fontSizeDefault,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (result['rating'] != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.star,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          result['rating'].toStringAsFixed(1),
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeExtraSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result['address'],
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).hintColor,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (result['types'] != null &&
                      result['types'].isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getPlaceTypeText(result['types']),
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
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

  String _getPlaceTypeText(List<dynamic> types) {
    if (types.isEmpty) return '';

    String primaryType = types.first.toString();

    switch (primaryType) {
      case 'airport':
        return 'Airport';
      case 'hospital':
        return 'Hospital';
      case 'gas_station':
        return 'Gas Station';
      case 'restaurant':
        return 'Restaurant';
      case 'shopping_mall':
        return 'Shopping Mall';
      case 'school':
        return 'School';
      case 'university':
        return 'University';
      case 'bank':
        return 'Bank';
      case 'mosque':
        return 'Mosque';
      case 'church':
        return 'Church';
      case 'park':
        return 'Park';
      case 'tourist_attraction':
        return 'Tourist Attraction';
      case 'lodging':
        return 'Hotel';
      default:
        return primaryType
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isNotEmpty
                ? '${word[0].toUpperCase()}${word.substring(1)}'
                : word)
            .join(' ');
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
                            onChanged: (value) {
                              // Real-time search as user types
                              if (value.length >= 2) {
                                _searchLocation();
                              }
                            },
                            onSubmitted: (_) => _searchLocation(),
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
                        else
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
