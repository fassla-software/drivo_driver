import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/location/controllers/location_controller.dart';

class CoordinatePickerScreenIOS extends StatefulWidget {
  final String title;
  final LatLng? initialPosition;

  const CoordinatePickerScreenIOS({
    super.key,
    required this.title,
    this.initialPosition,
  });

  @override
  State<CoordinatePickerScreenIOS> createState() =>
      _CoordinatePickerScreenIOSState();
}

class _CoordinatePickerScreenIOSState extends State<CoordinatePickerScreenIOS> {
  GoogleMapController? _mapController;
  LatLng? _selectedPosition;
  Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  bool _showResults = false;
  String? _selectedLocationName;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  void _initializeMap() async {
    if (widget.initialPosition != null) {
      _selectedPosition = widget.initialPosition;
      _addMarker(_selectedPosition!);
    } else {
      _selectedPosition = Get.find<LocationController>().initialPosition;
      _addMarker(_selectedPosition!);
    }
    setState(() {});
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
      Get.back(result: {
        'coordinates': _selectedPosition,
        'name': _selectedLocationName,
      });
    }
  }

  void _searchLocation(String value) async {
    // هنا يمكنك ربط البحث مع Apple Places API أو Google Places API
    // لأغراض الديمو سنضع نتائج وهمية
    setState(() {
      _isSearching = true;
      _showResults = true;
    });
    await Future.delayed(const Duration(milliseconds: 500));
    if (value.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _showResults = false;
      });
      return;
    }
    setState(() {
      _searchResults = [
        {
          'name': 'Apple Park',
          'address': 'Cupertino, CA',
          'lat': 37.3349,
          'lng': -122.0090,
        },
        {
          'name': 'San Francisco',
          'address': 'California, USA',
          'lat': 37.7749,
          'lng': -122.4194,
        },
      ];
      _isSearching = false;
      _showResults = true;
    });
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

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        previousPageTitle: 'Back',
      ),
      child: SafeArea(
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _selectedPosition ?? LatLng(37.3349, -122.0090),
                zoom: 16,
              ),
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              onTap: _onMapTap,
              markers: _markers,
              zoomControlsEnabled: false,
              myLocationButtonEnabled: false,
              myLocationEnabled: true,
            ),
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  CupertinoTextField(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    placeholder: 'Search for location',
                    onChanged: _searchLocation,
                    onTap: () {
                      setState(() {
                        _showResults = _searchController.text.isNotEmpty;
                      });
                    },
                    clearButtonMode: OverlayVisibilityMode.editing,
                    padding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                  if (_showResults)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      margin: const EdgeInsets.only(top: 2),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBackground
                            .resolveFrom(context),
                        borderRadius: BorderRadius.circular(12),
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
                                child: CupertinoActivityIndicator(),
                              ),
                            )
                          : _searchResults.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text('No locations found',
                                      style: TextStyle(
                                          color: CupertinoColors.inactiveGray)),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _searchResults.length,
                                  itemBuilder: (context, index) {
                                    final result = _searchResults[index];
                                    return CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () => _onResultTap(result),
                                      child: Container(
                                        alignment: Alignment.centerLeft,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 12, horizontal: 16),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(result['name'],
                                                style: const TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            Text(result['address'],
                                                style: const TextStyle(
                                                    color: CupertinoColors
                                                        .inactiveGray,
                                                    fontSize: 13)),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                    ),
                ],
              ),
            ),
            if (_selectedPosition != null)
              Positioned(
                bottom: 80,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        CupertinoColors.systemBackground.resolveFrom(context),
                    borderRadius: BorderRadius.circular(12),
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
                      Text(_selectedLocationName ?? 'Selected Coordinates',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                          'Lat: ${_selectedPosition!.latitude.toStringAsFixed(6)}'),
                      Text(
                          'Lng: ${_selectedPosition!.longitude.toStringAsFixed(6)}'),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: CupertinoButton.filled(
                onPressed: _selectedPosition != null ? _confirmSelection : null,
                child: const Text('Confirm Location'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
