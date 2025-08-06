import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/widgets/custom_icon_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/driver_header_info_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/expendale_bottom_sheet_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/theme/theme_controller.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/car_polling/domain/models/simple_trip_model.dart';
import 'package:ride_sharing_user_app/features/car_polling/controllers/carpool_main_map_controller.dart';

class CarpoolMainMapScreen extends StatefulWidget {
  final String fromScreen;
  final SimpleTripModel? carpoolTrip;

  const CarpoolMainMapScreen({
    super.key,
    this.fromScreen = 'carpool',
    this.carpoolTrip,
  });

  @override
  State<CarpoolMainMapScreen> createState() => _CarpoolMainMapScreenState();
}

class _CarpoolMainMapScreenState extends State<CarpoolMainMapScreen>
    with WidgetsBindingObserver {
  GoogleMapController? _mapController;
  GlobalKey<ExpandableBottomSheetState> key =
      GlobalKey<ExpandableBottomSheetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _findingCurrentRoute();
    Get.find<ProfileController>().stopLocationRecord();
  }

  _findingCurrentRoute() {
    // Initialize carpool main map controller
    if (widget.carpoolTrip != null) {
      Get.put(CarpoolMainMapController(carpoolTrip: widget.carpoolTrip!));
    }

    Get.find<RideController>().updateRoute(false, notify: false);

    if (Get.isRegistered<CarpoolMainMapController>()) {
      Get.find<CarpoolMainMapController>().setSheetHeight(300, false);
    }

    // Don't call getCurrentLocation here - it will be called in onMapCreated
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Handle app resume
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    Get.find<ProfileController>().startLocationRecord();
    super.dispose();
  }

  StreamSubscription? _locationSubscription;
  Marker? marker;
  GoogleMapController? _controller;

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load(Images.carTop);
    return byteData.buffer.asUint8List();
  }

  void updateMarkerAndCircle(Position? newLocalData, Uint8List imageData) {
    LatLng latLng = LatLng(newLocalData!.latitude, newLocalData.longitude);
    setState(() {
      marker = Marker(
          markerId: const MarkerId("home"),
          position: latLng,
          rotation: newLocalData.heading,
          draggable: false,
          zIndex: 2,
          flat: true,
          anchor: const Offset(0.5, 0.5),
          icon: BitmapDescriptor.fromBytes(imageData));
    });
  }

  void getCurrentLocation() async {
    try {
      Uint8List imageData = await getMarker();
      var location = await Geolocator.getCurrentPosition();
      updateMarkerAndCircle(location, imageData);

      // Update car position in carpool controller immediately
      if (Get.isRegistered<CarpoolMainMapController>()) {
        Get.find<CarpoolMainMapController>().updateMarkerAndCircle(
          LatLng(location.latitude, location.longitude),
        );
      }

      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10, // Increased to reduce API calls
        ),
      ).listen((newLocalData) {
        if (_controller != null && mounted) {
          try {
            // Update car position in carpool controller like in original map screen
            if (Get.isRegistered<CarpoolMainMapController>()) {
              Get.find<CarpoolMainMapController>().updateMarkerAndCircle(
                LatLng(newLocalData.latitude, newLocalData.longitude),
              );
            }

            // Only call getCurrentLocation if following driver
            if (Get.isRegistered<CarpoolMainMapController>() &&
                Get.find<CarpoolMainMapController>().isFollowingDriver) {
              Get.find<LocationController>()
                  .getCurrentLocation(callZone: false);
            }

            // Only move camera if following driver
            if (Get.isRegistered<CarpoolMainMapController>() &&
                Get.find<CarpoolMainMapController>().isFollowingDriver) {
              _controller!.moveCamera(CameraUpdate.newCameraPosition(
                  CameraPosition(
                      bearing: newLocalData.heading,
                      target:
                          LatLng(newLocalData.latitude, newLocalData.longitude),
                      tilt: 0,
                      zoom: 16)));
            }

            updateMarkerAndCircle(newLocalData, imageData);
          } catch (e) {
            debugPrint('Camera move error: $e');
          }
        }
      }, onError: (error) {
        debugPrint('Location stream error: $error');
      });
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        debugPrint("Permission Denied");
      } else {
        debugPrint("Platform exception: $e");
      }
    } catch (e) {
      debugPrint("General error in getCurrentLocation: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: Navigator.canPop(context),
      onPopInvokedWithResult: (res, val) {
        if (res) {
          Get.find<RideController>().getOngoingParcelList();
          Get.find<RideController>().getLastTrip();
          Get.find<RideController>().updateRoute(true, notify: true);
        } else {
          Get.offAll(() => const DashboardScreen());
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: GetBuilder<CarpoolMainMapController>(
            builder: (carpoolMainMapController) {
          return GetBuilder<RideController>(builder: (rideController) {
            return ExpandableBottomSheet(
              key: key,
              persistentContentHeight: carpoolMainMapController.sheetHeight,
              background: GetBuilder<RideController>(builder: (rideController) {
                return Stack(children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: carpoolMainMapController.sheetHeight - 80,
                    ),
                    child: GoogleMap(
                      style: Get.isDarkMode
                          ? Get.find<ThemeController>().darkMap
                          : Get.find<ThemeController>().lightMap,
                      initialCameraPosition: CameraPosition(
                        target: widget.carpoolTrip?.startCoordinates != null
                            ? LatLng(
                                widget.carpoolTrip!.startCoordinates![1],
                                widget.carpoolTrip!.startCoordinates![0],
                              )
                            : Get.find<LocationController>().initialPosition,
                        zoom: 15.0,
                        bearing: 0,
                        tilt: 0,
                      ),
                      onMapCreated: (GoogleMapController controller) async {
                        try {
                          carpoolMainMapController.setMapController(controller);
                          _mapController = controller;
                          _controller = controller;

                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          // Initialize map like in original map screen
                          await carpoolMainMapController.initializeMap();

                          // Get current location once
                          getCurrentLocation();

                          // Start location tracking like in original map screen
                          carpoolMainMapController.startLocationTracking();
                        } catch (e) {
                          debugPrint('Error in onMapCreated: $e');
                        }
                      },
                      onCameraMove: (CameraPosition cameraPosition) {
                        // Handle camera move like in original map screen
                        if (Get.isRegistered<CarpoolMainMapController>()) {
                          Get.find<CarpoolMainMapController>().onCameraMove();
                        }
                      },
                      onCameraIdle: () {},
                      minMaxZoomPreference:
                          const MinMaxZoomPreference(0, AppConstants.mapZoom),
                      markers: Set<Marker>.of(carpoolMainMapController.markers),
                      polylines: carpoolMainMapController.polylines,
                      zoomControlsEnabled: false,
                      compassEnabled: true,
                      trafficEnabled: carpoolMainMapController.isTrafficEnable,
                      indoorViewEnabled: true,
                      mapToolbarEnabled: false,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.to(const ProfileScreen()),
                    child: const DriverHeaderInfoWidget(),
                  ),
                  Positioned(
                      bottom: Get.width * 0.9,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GetBuilder<LocationController>(
                            builder: (locationController) {
                          return CustomIconCardWidget(
                            title: '',
                            index: 5,
                            icon: carpoolMainMapController.isTrafficEnable
                                ? Images.trafficOnlineIcon
                                : Images.trafficOfflineIcon,
                            iconColor: carpoolMainMapController.isTrafficEnable
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor,
                            onTap: () =>
                                carpoolMainMapController.toggleTrafficView(),
                          );
                        }),
                      )),
                  Positioned(
                      bottom: Get.width * 0.78,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GetBuilder<LocationController>(
                            builder: (locationController) {
                          return CustomIconCardWidget(
                            iconColor: Theme.of(context).primaryColor,
                            title: '',
                            index: 5,
                            icon: Images.currentLocation,
                            onTap: () async {
                              await locationController.getCurrentLocation(
                                  mapController: _mapController,
                                  isAnimate: false);
                            },
                          );
                        }),
                      )),
                  // Home Button
                ]);
              }),
              persistentHeader: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag indicator
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).hintColor.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Trip header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Carpool Trip #${widget.carpoolTrip?.id ?? 'N/A'}',
                                  style: textBold.copyWith(
                                    fontSize: Dimensions.fontSizeDefault,
                                  ),
                                ),
                                Text(
                                  widget.carpoolTrip?.isTripStarted == 1
                                      ? 'Active Trip'
                                      : 'Pending Trip',
                                  style: textRegular.copyWith(
                                    fontSize: Dimensions.fontSizeSmall,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: widget.carpoolTrip?.isTripStarted == 1
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              widget.carpoolTrip?.formattedPrice ?? 'N/A',
                              style: textBold.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Trip details in header
                    if (widget.carpoolTrip != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: _buildHeaderDetailRow(
                                icon: Icons.location_on,
                                title: 'From',
                                subtitle:
                                    widget.carpoolTrip!.startAddress ?? 'N/A',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildHeaderDetailRow(
                                icon: Icons.location_on_outlined,
                                title: 'To',
                                subtitle:
                                    widget.carpoolTrip!.endAddress ?? 'N/A',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              expandableContent: Builder(builder: (context) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.carpoolTrip != null) ...[
                        // Trip stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.people,
                                title: 'Passengers',
                                value:
                                    '${widget.carpoolTrip!.passengersCount ?? 0}',
                              ),
                            ),
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.event_seat,
                                title: 'Available',
                                value:
                                    '${widget.carpoolTrip!.availableSeats ?? 0}',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _buildSimpleStatCard(
                                icon: Icons.access_time,
                                title: 'Time',
                                value: widget.carpoolTrip!.startHour ?? 'N/A',
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.fitMarkersOnMap();
                                },
                                icon: const Icon(Icons.fit_screen, size: 18),
                                label: Text('Fit Map'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.openInGoogleMaps();
                                },
                                icon: const Icon(Icons.open_in_new, size: 18),
                                label: Text('Open Maps'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  carpoolMainMapController.returnToDriver();
                                },
                                icon: const Icon(Icons.location_on, size: 18),
                                label: Text('My Location'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Follow Driver Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              carpoolMainMapController.toggleFollowDriver();
                            },
                            icon: Icon(
                              carpoolMainMapController.isFollowingDriver
                                  ? Icons.gps_fixed
                                  : Icons.gps_not_fixed,
                              size: 18,
                            ),
                            label: Text(
                              carpoolMainMapController.isFollowingDriver
                                  ? 'Following Driver'
                                  : 'Follow Driver',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  carpoolMainMapController.isFollowingDriver
                                      ? Theme.of(context).primaryColor
                                      : Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              }),
            );
          });
        }),
      ),
    );
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == 0) return;
    if (details.primaryVelocity!.compareTo(0) == -1) {
    } else {}
  }

  // Helper methods for UI components
  Widget _buildHeaderDetailRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              title,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildSimpleStatCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeSmall,
            ),
          ),
          Text(
            title,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }
}
