import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

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

class MapScreen extends StatefulWidget {
  final String fromScreen;
  const MapScreen({super.key, this.fromScreen = 'home'});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
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
    Get.find<RideController>().updateRoute(false, notify: false);
    Get.find<RiderMapController>().setSheetHeight(
        Get.find<RiderMapController>().currentRideState == RideState.initial
            ? 300
            : 270,
        false);
    Get.find<RideController>().getPendingRideRequestList(1);
    if (Get.find<RideController>().ongoingTrip != null &&
        Get.find<RideController>().ongoingTrip!.isNotEmpty &&
        (Get.find<RideController>().ongoingTrip![0].currentStatus ==
                'ongoing' ||
            Get.find<RideController>().ongoingTrip![0].currentStatus ==
                'accepted' ||
            (Get.find<RideController>().ongoingTrip![0].currentStatus ==
                    'completed' &&
                Get.find<RideController>().ongoingTrip![0].paymentStatus ==
                    'unpaid'))) {
      // Get.find<RideController>().getCurrentRideStatus(froDetails: true, isUpdate: false);
      Get.find<RiderMapController>().setMarkersInitialPosition();
    } else {
      // Add current location marker when no ongoing trip
      Get.find<RiderMapController>().myCurrentLocation();
    }
    getCurrentLocation();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Get.find<RideController>().getCurrentRideStatus(froDetails: true, isUpdate: false,fromMapScreen: true);
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    if (_locationSubscription != null) {
      _locationSubscription!.cancel();
    }
    _interpolationTimer?.cancel();
    _positionHistory.clear(); // Clear position history
    Get.find<ProfileController>().startLocationRecord();

    super.dispose();
  }

  StreamSubscription? _locationSubscription;
  Marker? marker;
  GoogleMapController? _controller;
  Position? _lastPosition;
  Timer? _interpolationTimer;
  List<Position> _positionHistory = [];
  static const int _maxHistorySize = 5;
  static const double _minMovementThreshold = 2.0; // meters
  static const double _maxSpeedThreshold = 50.0; // m/s (180 km/h)

  Future<Uint8List> getMarker() async {
    ByteData byteData =
        await DefaultAssetBundle.of(context).load(Images.carTop);
    return byteData.buffer.asUint8List();
  }

  double _calculateBearing(LatLng start, LatLng end) {
    double startLat = start.latitude * (3.14159 / 180);
    double startLng = start.longitude * (3.14159 / 180);
    double endLat = end.latitude * (3.14159 / 180);
    double endLng = end.longitude * (3.14159 / 180);

    double dLng = endLng - startLng;

    double y = sin(dLng) * cos(endLat);
    double x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x);
    bearing = bearing * (180 / 3.14159);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  Position _filterGPSNoise(Position newPosition) {
    // Add to position history
    _positionHistory.add(newPosition);
    if (_positionHistory.length > _maxHistorySize) {
      _positionHistory.removeAt(0);
    }
    
    // If we don't have enough history, return the position as is
    if (_positionHistory.length < 3) {
      return newPosition;
    }
    
    // Calculate average position from recent history for smoothing
    double avgLat = _positionHistory.map((p) => p.latitude).reduce((a, b) => a + b) / _positionHistory.length;
    double avgLng = _positionHistory.map((p) => p.longitude).reduce((a, b) => a + b) / _positionHistory.length;
    
    // Check if the new position is too far from the average (potential GPS jump)
    double distanceFromAverage = Geolocator.distanceBetween(
      avgLat, avgLng, newPosition.latitude, newPosition.longitude
    );
    
    // If the position seems like a GPS jump, use a weighted average instead
    if (distanceFromAverage > 20.0 && newPosition.accuracy > 10.0) {
      // Use weighted average: 70% previous smooth position, 30% new position
      double smoothLat = avgLat * 0.7 + newPosition.latitude * 0.3;
      double smoothLng = avgLng * 0.7 + newPosition.longitude * 0.3;
      
      return Position(
        latitude: smoothLat,
        longitude: smoothLng,
        timestamp: newPosition.timestamp,
        accuracy: newPosition.accuracy,
        altitude: newPosition.altitude,
        heading: newPosition.heading,
        speed: newPosition.speed,
        speedAccuracy: newPosition.speedAccuracy,
        altitudeAccuracy: newPosition.altitudeAccuracy,
        headingAccuracy: newPosition.headingAccuracy,
      );
    }
    
    return newPosition;
  }
  
  bool _shouldUpdatePosition(Position newPosition) {
    if (_lastPosition == null) return true;
    
    // Calculate distance moved
    double distance = Geolocator.distanceBetween(
      _lastPosition!.latitude,
      _lastPosition!.longitude,
      newPosition.latitude,
      newPosition.longitude,
    );
    
    // Don't update if movement is too small (reduces jitter)
    if (distance < _minMovementThreshold) {
      return false;
    }
    
    // Check for unrealistic speed (potential GPS error)
    double timeDiff = newPosition.timestamp.difference(_lastPosition!.timestamp).inMilliseconds / 1000.0;
    if (timeDiff > 0) {
      double speed = distance / timeDiff;
      if (speed > _maxSpeedThreshold) {
        debugPrint('Rejecting position update due to unrealistic speed: ${speed.toStringAsFixed(2)} m/s');
        return false;
      }
    }
    
    return true;
  }
  
  void _smoothMoveToPosition(Position fromPosition, Position toPosition, Uint8List imageData) {
    _interpolationTimer?.cancel();
    
    const int steps = 10; // Increased steps for smoother movement
    const Duration stepDuration = Duration(milliseconds: 100); // 100ms per step (1 second total)
    int currentStep = 0;
    
    // Calculate bearing for smooth camera rotation
    double startBearing = _calculateBearing(
      LatLng(fromPosition.latitude, fromPosition.longitude),
      LatLng(toPosition.latitude, toPosition.longitude)
    );
    
    _interpolationTimer = Timer.periodic(stepDuration, (timer) {
      if (currentStep >= steps || !mounted) {
        timer.cancel();
        updateMarkerAndCircle(toPosition, imageData);
        // Smooth camera animation with bearing
        _controller?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(toPosition.latitude, toPosition.longitude),
              zoom: 16,
              bearing: startBearing,
              tilt: 0,
            ),
          ),
        );
        return;
      }
      
      double progress = _easeInOutCubic(currentStep / steps); // Smooth easing
      double lat = fromPosition.latitude + (toPosition.latitude - fromPosition.latitude) * progress;
      double lng = fromPosition.longitude + (toPosition.longitude - fromPosition.longitude) * progress;
      
      Position interpolatedPosition = Position(
        latitude: lat,
        longitude: lng,
        timestamp: DateTime.now(),
        accuracy: toPosition.accuracy,
        altitude: toPosition.altitude,
        heading: toPosition.heading,
        speed: toPosition.speed,
        speedAccuracy: toPosition.speedAccuracy,
        altitudeAccuracy: toPosition.altitudeAccuracy,
        headingAccuracy: toPosition.headingAccuracy,
      );
      
      updateMarkerAndCircle(interpolatedPosition, imageData);
      currentStep++;
    });
  }
  
  // Smooth easing function for better animation
  double _easeInOutCubic(double t) {
    return t < 0.5 ? 4 * t * t * t : 1 - pow(-2 * t + 2, 3) / 2;
  }
  
  // Error handling and fallback mechanisms
  void _handleLocationError(dynamic error, Uint8List imageData) {
    debugPrint('Handling location error: $error');
    
    // Try to get last known position as fallback
    Geolocator.getLastKnownPosition().then((lastKnownPosition) {
      if (lastKnownPosition != null && mounted) {
        debugPrint('Using last known position as fallback');
        updateMarkerAndCircle(lastKnownPosition, imageData);
        _lastPosition = lastKnownPosition;
      } else {
        // If no last known position, try to restart location stream after delay
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            debugPrint('Attempting to restart location stream');
            _restartLocationStream(imageData);
          }
        });
      }
    }).catchError((e) {
      debugPrint('Failed to get last known position: $e');
      // Final fallback - restart location stream after longer delay
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          debugPrint('Final fallback: restarting location stream');
          _restartLocationStream(imageData);
        }
      });
    });
  }
  
  void _restartLocationStream(Uint8List imageData) {
    try {
      _locationSubscription?.cancel();
      _positionHistory.clear(); // Clear history when restarting
      
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.medium, // Use medium accuracy for fallback
          distanceFilter: 5, // Slightly larger distance filter
          timeLimit: Duration(seconds: 5), // Longer timeout
        ),
      ).listen((newLocalData) {
        if (_controller != null && mounted) {
          try {
            // Apply GPS noise filtering
            Position filteredPosition = _filterGPSNoise(newLocalData);
            
            // Check if we should update the position
            if (!_shouldUpdatePosition(filteredPosition)) {
              return; // Skip this update
            }
            
            Get.find<RideController>()
                .remainingDistance(Get.find<RideController>().tripDetail!.id!);
            Get.find<LocationController>().getCurrentLocation(callZone: false);

            if (_lastPosition != null) {
              _smoothMoveToPosition(_lastPosition!, filteredPosition, imageData);
            } else {
              updateMarkerAndCircle(filteredPosition, imageData);
            }
            _lastPosition = filteredPosition;
          } catch (e) {
            debugPrint('Error in restarted location stream: $e');
          }
        }
      }, onError: (error) {
        debugPrint('Restarted location stream error: $error');
        // If restart fails, try again after longer delay
        Future.delayed(const Duration(seconds: 15), () {
          if (mounted) {
            _restartLocationStream(imageData);
          }
        });
      });
    } catch (e) {
      debugPrint('Failed to restart location stream: $e');
    }
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
      _lastPosition = location;
      updateMarkerAndCircle(location, imageData);

      if (_locationSubscription != null) {
        _locationSubscription!.cancel();
      }

      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 1, // Reduced to 1 meter for more responsive updates
          timeLimit: Duration(seconds: 3), // Maximum 3 second intervals
        ),
      ).listen((newLocalData) {
        if (_controller != null && mounted) {
          try {
            // Apply GPS noise filtering
            Position filteredPosition = _filterGPSNoise(newLocalData);
            
            // Check if we should update the position
            if (!_shouldUpdatePosition(filteredPosition)) {
              return; // Skip this update
            }
            
            print("start");
            Get.find<RideController>()
                .remainingDistance(Get.find<RideController>().tripDetail!.id!);
            Get.find<LocationController>().getCurrentLocation(callZone: false);

            // Smooth interpolation between positions
            if (_lastPosition != null) {
              _smoothMoveToPosition(_lastPosition!, filteredPosition, imageData);
            } else {
              _controller!.animateCamera(CameraUpdate.newCameraPosition(
                   CameraPosition(
                       bearing: 192.8334901395799,
                       target:
                           LatLng(filteredPosition.latitude, filteredPosition.longitude),
                       tilt: 0,
                       zoom: 16)));
              updateMarkerAndCircle(filteredPosition, imageData);
            }
            _lastPosition = filteredPosition;
          } catch (e) {
            debugPrint('Camera move error: $e');
            // Optionally retry after a delay
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_controller != null && mounted) {
                try {
                  _controller!.animateCamera(CameraUpdate.newCameraPosition(
                      CameraPosition(
                          target: LatLng(
                              newLocalData.latitude, newLocalData.longitude),
                          zoom: 16)));
                } catch (retryError) {
                  debugPrint('Retry camera move failed: $retryError');
                }
              }
            });
          }
        }
      }, onError: (error) {
        debugPrint('Location stream error: $error');
        _handleLocationError(error, imageData);
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
        body: GetBuilder<RiderMapController>(builder: (riderMapController) {
          return GetBuilder<RideController>(builder: (rideController) {
            return ExpandableBottomSheet(
              key: key,
              persistentContentHeight: riderMapController.sheetHeight,
              background: GetBuilder<RideController>(builder: (rideController) {
                return Stack(children: [
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: riderMapController.sheetHeight -
                          (Get.find<RiderMapController>().currentRideState ==
                                  RideState.initial
                              ? 80
                              : 20),
                    ),
                    child: GoogleMap(
                      style: Get.isDarkMode
                          ? Get.find<ThemeController>().darkMap
                          : Get.find<ThemeController>().lightMap,
                      initialCameraPosition: CameraPosition(
                        target: (rideController.tripDetail != null &&
                                rideController.tripDetail!.pickupCoordinates !=
                                    null)
                            ? LatLng(
                                rideController.tripDetail!.pickupCoordinates!
                                    .coordinates![1],
                                rideController.tripDetail!.pickupCoordinates!
                                    .coordinates![0],
                              )
                            : Get.find<LocationController>().initialPosition,
                        zoom: 16,
                      ),
                      onMapCreated: (GoogleMapController controller) async {
                        try {
                          riderMapController.mapController = controller;
                          _mapController = controller;
                          _controller = controller;

                          // Add a small delay to ensure map is fully ready
                          await Future.delayed(
                              const Duration(milliseconds: 100));

                          if (riderMapController.currentRideState.name !=
                              'initial') {
                            if (riderMapController.currentRideState.name ==
                                    'accepted' ||
                                riderMapController.currentRideState.name ==
                                    'ongoing') {
                              Get.find<RideController>().remainingDistance(
                                  Get.find<RideController>().tripDetail!.id!,
                                  mapBound: true);
                            } else {
                              riderMapController
                                  .getPickupToDestinationPolyline();
                            }
                          } else {
                            await riderMapController.myCurrentLocation();
                          }
                        } catch (e) {
                          debugPrint('Error in onMapCreated: $e');
                        }
                      },
                      onCameraMove: (CameraPosition cameraPosition) {},
                      onCameraIdle: () {},
                      minMaxZoomPreference:
                          const MinMaxZoomPreference(0, AppConstants.mapZoom),
                      markers: Set<Marker>.of(riderMapController.markers),
                      polylines: riderMapController.polylines,
                      zoomControlsEnabled: false,
                      compassEnabled: false,
                      trafficEnabled: riderMapController.isTrafficEnable,
                      indoorViewEnabled: true,
                      mapToolbarEnabled: true,
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.to(const ProfileScreen()),
                    child: const DriverHeaderInfoWidget(),
                  ),
                  Positioned(
                      bottom: Get.width * 0.87,
                      right: 0,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: GetBuilder<LocationController>(
                            builder: (locationController) {
                          return CustomIconCardWidget(
                            title: '',
                            index: 5,
                            icon: riderMapController.isTrafficEnable
                                ? Images.trafficOnlineIcon
                                : Images.trafficOfflineIcon,
                            iconColor: riderMapController.isTrafficEnable
                                ? Theme.of(context).primaryColor
                                : Theme.of(context).primaryColor,
                            onTap: () => riderMapController.toggleTrafficView(),
                          );
                        }),
                      )),
                  Positioned(
                      bottom: Get.width * 0.73,
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
                  Positioned(
                      child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Get.find<RideController>()
                            .updateRoute(true, notify: true);
                        Get.off(() => const DashboardScreen());
                      },
                      onHorizontalDragEnd: (DragEndDetails details) {
                        _onHorizontalDrag(details);
                        Get.find<RideController>()
                            .updateRoute(true, notify: true);
                        Get.off(() => const DashboardScreen());
                      },
                      child: Stack(children: [
                        SizedBox(
                            width: Dimensions.iconSizeExtraLarge,
                            child: Image.asset(
                              Images.mapToHomeIcon,
                              color: Theme.of(context).primaryColor,
                            )),
                        Positioned(
                            top: 0,
                            bottom: 0,
                            left: 5,
                            right: 5,
                            child: SizedBox(
                                width: 15,
                                child: Image.asset(Images.homeSmallIcon,
                                    color: Colors.white)))
                      ]),
                    ),
                  )),
                ]);
              }),
              persistentHeader: SizedBox(
                  height: 50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(child:
                          GetBuilder<RideController>(builder: (rideController) {
                        return InkWell(
                          onTap: () => Get.to(() => const RideRequestScreen()),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeExtraLarge),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: Dimensions.paddingSizeDefault,
                                vertical: Dimensions.paddingSizeSmall,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                      height: Dimensions.iconSizeSmall,
                                      child: Image.asset(Images.reqListIcon)),
                                  const SizedBox(
                                      width: Dimensions.paddingSizeSmall),
                                  Text(
                                    '${rideController.pendingRideRequestModel?.totalSize ?? 0} ${'more_request'.tr}',
                                    style: textRegular.copyWith(
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      })),
                    ],
                  )),
              expandableContent: Builder(builder: (context) {
                return Column(mainAxisSize: MainAxisSize.min, children: [
                  RiderBottomSheetWidget(expandableKey: key),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                ]);
              }),
            );
          });
        }),
      ),
    );
  }

  void _onHorizontalDrag(DragEndDetails details) {
    if (details.primaryVelocity == 0)
      return; // user have just tapped on screen (no dragging)

    if (details.primaryVelocity!.compareTo(0) == -1) {
    } else {}
  }
}
