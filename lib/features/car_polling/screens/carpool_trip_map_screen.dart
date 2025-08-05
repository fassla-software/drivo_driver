import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:flutter/services.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../theme/theme_controller.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../../util/images.dart';
import '../domain/models/current_trips_with_passengers_response_model.dart';
import '../domain/models/carpool_routes_response_model.dart';
import '../controllers/carpool_trip_map_controller.dart';
import 'package:geolocator/geolocator.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';

class CarpoolTripMapScreen extends StatefulWidget {
  final CurrentTrip trip;

  const CarpoolTripMapScreen({
    super.key,
    required this.trip,
  });

  @override
  State<CarpoolTripMapScreen> createState() => _CarpoolTripMapScreenState();
}

class _CarpoolTripMapScreenState extends State<CarpoolTripMapScreen> {
  late CarpoolTripMapController _mapController;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() async {
    try {
      // Check if controller already exists and remove it
      if (Get.isRegistered<CarpoolTripMapController>()) {
        Get.delete<CarpoolTripMapController>();
      }

      // Create new controller
      _mapController = Get.put(CarpoolTripMapController());

      // Initialize trip (this method is void, so no await needed)
      _mapController.initializeTrip(widget.trip);

      debugPrint('Carpool trip map controller initialized successfully');

      // Set a timeout to force the screen to show even if initialization hangs
      Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() {
            // Force rebuild to show the map
          });
        }
      });
    } catch (e) {
      debugPrint('Error initializing carpool trip map controller: $e');
      // Force loading to false to prevent infinite loading
      setState(() {
        // This will trigger a rebuild and show the map
      });
    }
  }

  @override
  void dispose() {
    Get.delete<CarpoolTripMapController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // تحقق من وجود إحداثيات البداية والنهاية
    final trip = widget.trip;
    print(trip.startCoordinates);
    print(trip.endCoordinates);
    if (trip.startCoordinates == null || trip.endCoordinates == null) {
      return Scaffold(
        appBar: AppBarWidget(
          title: 'trip_map'.tr,
          showBackButton: true,
        ),
        body: Center(
          child: Text(
            'لا يمكن عرض الخريطة: لا توجد إحداثيات للمسار',
            style: textMedium.copyWith(
              color: Colors.red,
              fontSize: Dimensions.fontSizeLarge,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // رسم مسار بسيط بين نقطة البداية والنهاية
    final LatLng start =
        LatLng(trip.startCoordinates![1], trip.startCoordinates![0]);
    final LatLng end = LatLng(trip.endCoordinates![1], trip.endCoordinates![0]);

    // طباعة الإحداثيات للتأكد من صحتها
    print('============== TRIP COORDINATES ==============');
    print('Start Coordinates: ${trip.startCoordinates}');
    print('End Coordinates: ${trip.endCoordinates}');
    print('Start LatLng: ${start.latitude}, ${start.longitude}');
    print('End LatLng: ${end.latitude}, ${end.longitude}');
    print('==============================================');

    return Scaffold(
      appBar: AppBarWidget(
        title: 'trip_map'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<CarpoolTripMapController>(
        builder: (controller) {
          // Show loading only for a short time, then show map anyway
          if (controller.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Initializing map...',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeDefault,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This may take a few seconds',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          // خط بين موقع السائق الحالي ونقطة البداية
          Set<Polyline> polylines = {
            Polyline(
              polylineId: const PolylineId('simple_route'),
              points: [start, end],
              color: Colors.blue,
              width: 5,
            ),
          };

          // إضافة markers للنقاط الأساسية
          Set<Marker> baseMarkers = {
            Marker(
              markerId: const MarkerId('start_point'),
              position: start,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: InfoWindow(
                title: 'نقطة البداية',
                snippet:
                    '${start.latitude.toStringAsFixed(6)}, ${start.longitude.toStringAsFixed(6)}',
              ),
            ),
            Marker(
              markerId: const MarkerId('end_point'),
              position: end,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed),
              infoWindow: InfoWindow(
                title: 'نقطة النهاية',
                snippet:
                    '${end.latitude.toStringAsFixed(6)}, ${end.longitude.toStringAsFixed(6)}',
              ),
            ),
          };

          // دمج markers الأساسية مع markers المتحكم
          Set<Marker> allMarkers = {...baseMarkers, ...controller.markers};
          try {
            if (controller.driverPosition != null) {
              final LatLng driver = controller.driverPosition!;
              // تحقق من أن الإحداثيات ليست NaN
              if (!driver.latitude.isNaN &&
                  !driver.longitude.isNaN &&
                  !start.latitude.isNaN &&
                  !start.longitude.isNaN) {
                // تحقق من أن المسافة ليست ضخمة جدًا
                double distance = 0;
                try {
                  distance = Geolocator.distanceBetween(
                    driver.latitude,
                    driver.longitude,
                    start.latitude,
                    start.longitude,
                  );
                } catch (e) {
                  distance = 0;
                }
                if (distance < 1000000) {
                  // أقل من 1000 كم
                  polylines.add(
                    Polyline(
                      polylineId: const PolylineId('driver_to_start'),
                      points: [driver, start],
                      color: Colors.orange,
                      width: 4,
                      patterns: [PatternItem.dash(15), PatternItem.gap(8)],
                    ),
                  );
                }
              }
            }
          } catch (e) {
            debugPrint('Polyline or camera error: $e');
          }

          return Column(
            children: [
              // Trip Info Header
              _buildTripInfoHeader(controller),

              // Map
              Expanded(
                child: Stack(
                  children: [
                    GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: start,
                        zoom: 14,
                      ),
                      onMapCreated: (GoogleMapController mapController) {
                        controller.setMapController(mapController);

                        // تمركز الخريطة على المسار بعد إنشائها
                        Timer(const Duration(milliseconds: 500), () {
                          if (mapController != null) {
                            mapController.animateCamera(
                              CameraUpdate.newLatLngBounds(
                                _getBoundsForRoute(start, end),
                                50.0, // padding
                              ),
                            );
                          }
                        });
                      },
                      markers: allMarkers,
                      polylines: polylines,
                      style: Get.isDarkMode
                          ? Get.find<ThemeController>().darkMap
                          : Get.find<ThemeController>().lightMap,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      compassEnabled: true,
                      myLocationButtonEnabled: false,
                    ),

                    // Driver tracking controls
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Column(
                        children: [
                          // Follow driver button
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: controller.followDriver,
                              icon: Icon(
                                Icons.my_location,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'follow_driver'.tr,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Center on driver button
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: controller.centerOnDriver,
                              icon: Icon(
                                Icons.center_focus_strong,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'center_on_driver'.tr,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Refresh zone button
                          Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: () async {
                                await controller.refreshZone();
                                Get.showSnackbar(GetSnackBar(
                                  title: 'Zone Updated',
                                  message:
                                      'Current zone: ${controller.getCurrentZoneId()}',
                                  duration: const Duration(seconds: 2),
                                ));
                              },
                              icon: Icon(
                                Icons.refresh,
                                color: Theme.of(context).primaryColor,
                              ),
                              tooltip: 'refresh_zone'.tr,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Passengers dropdown list
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _buildPassengersDropdown(controller),
                    ),

                    // Polyline loading indicator
                    if (controller.isLoadingPolylines)
                      Positioned(
                        top: 16,
                        right: 16,
                        child: Container(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'loading_routes'.tr,
                                style: textRegular.copyWith(
                                  fontSize: Dimensions.fontSizeSmall,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Driver location and zone indicator
                    if (controller.driverPosition != null)
                      Positioned(
                        bottom: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Driver location indicator
                            Container(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.green,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'driver_location'.tr,
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Zone indicator
                            Container(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeSmall),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.map,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Zone: ${controller.getCurrentZoneId().isNotEmpty ? controller.getCurrentZoneId() : 'Unknown'}',
                                    style: textRegular.copyWith(
                                      fontSize: Dimensions.fontSizeSmall,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // Nearby passengers indicator
                            if (controller.nearbyPassengers.isNotEmpty)
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                child: GestureDetector(
                                  onTap: () {
                                    // Show dialog for the first nearby passenger
                                    if (controller
                                        .nearbyPassengers.isNotEmpty) {
                                      controller.showProximityDialog(
                                          controller.nearbyPassengers.first);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(
                                        Dimensions.paddingSizeSmall),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.orange.withValues(alpha: 0.95),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                          color: Colors.orange.shade600,
                                          width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.2),
                                          blurRadius: 6,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.person_add,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              '${controller.nearbyPassengers.length} مستخدم قريب',
                                              style: textRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'اضغط للاستلام',
                                          style: textRegular.copyWith(
                                            fontSize: 10,
                                            color: Colors.white
                                                .withValues(alpha: 0.8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Legend
              _buildLegend(controller),

              // Passengers Info Panel
              if ((trip.acceptedPassengers != null &&
                      trip.acceptedPassengers!.isNotEmpty) ||
                  (trip.pendingPassengers != null &&
                      trip.pendingPassengers!.isNotEmpty))
                _buildPassengersPanel(trip),
            ],
          );
        },
      ),
      floatingActionButton: GetBuilder<CarpoolTripMapController>(
        builder: (controller) {
          return FloatingActionButton(
            onPressed: controller.fitMarkersOnMap,
            backgroundColor: Theme.of(context).primaryColor,
            child: const Icon(Icons.center_focus_strong, color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildTripInfoHeader(CarpoolTripMapController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: controller.getTripStatusColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  controller.getTripStatusText(),
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${'route_id'.tr} #${controller.currentTrip.routeId}',
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              Icon(Icons.people, size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 4),
              Text(
                '${controller.currentTrip.totalAcceptedPassengers ?? 0} ${'passengers'.tr}',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Icon(Icons.attach_money,
                  size: 16, color: Theme.of(context).hintColor),
              const SizedBox(width: 4),
              Text(
                '${controller.currentTrip.price?.toStringAsFixed(2) ?? '0'} EGP/${'seat'.tr}',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(CarpoolTripMapController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'map_legend'.tr,
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Wrap(
            spacing: Dimensions.paddingSizeDefault,
            runSpacing: Dimensions.paddingSizeExtraSmall,
            children: [
              _buildLegendItem(
                  Colors.green, Icons.play_arrow, 'start_point'.tr),
              _buildLegendItem(Colors.red, Icons.location_on, 'end_point'.tr),
              _buildLegendItem(
                  Colors.blue, Icons.person_pin_circle, 'pickup_points'.tr),
              _buildLegendItem(
                  Colors.orange, Icons.person_pin, 'dropoff_points'.tr),
              _buildPolylineLegendItem(
                  Theme.of(context).primaryColor, 'main_route'.tr),
              _buildPolylineLegendItem(Colors.blue, 'passenger_routes'.tr),
              // Add driver marker to legend
              _buildLegendItem(
                  Colors.green, Icons.directions_car, 'driver_location'.tr),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPolylineLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1.5),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPassengersDropdown(CarpoolTripMapController controller) {
    final availablePassengers = controller.availablePassengers;
    final pickedUpPassengers = controller.pickedUpPassengers;

    if (availablePassengers.isEmpty && pickedUpPassengers.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          'no_passengers'.tr,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
      );
    }

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              Icons.people,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'passengers'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
                color: Theme.of(context).primaryColor,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${availablePassengers.length + pickedUpPassengers.length}',
                style: textMedium.copyWith(
                  color: Colors.white,
                  fontSize: Dimensions.fontSizeExtraSmall,
                ),
              ),
            ),
          ],
        ),
        children: [
          // Available passengers (not picked up)
          if (availablePassengers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
              ),
              child: Text(
                'available_passengers'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.orange,
                ),
              ),
            ),
            ...availablePassengers.map((passenger) => _buildPassengerItem(
                  controller,
                  passenger,
                  isPickedUp: false,
                )),
          ],

          // Picked up passengers
          if (pickedUpPassengers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeSmall,
              ),
              child: Text(
                'picked_up_passengers'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.green,
                ),
              ),
            ),
            ...pickedUpPassengers.map((passenger) => _buildPassengerItem(
                  controller,
                  passenger,
                  isPickedUp: true,
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerItem(
      CarpoolTripMapController controller, AcceptedPassenger passenger,
      {required bool isPickedUp}) {
    final isPickupInProgress =
        controller.isPickupInProgress(passenger.carpoolTripId ?? '');

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: 2,
      ),
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: isPickedUp
            ? Colors.green.withValues(alpha: 0.1)
            : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isPickedUp
              ? Colors.green.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                backgroundImage: passenger.profileImage != null
                    ? NetworkImage(passenger.profileImage!)
                    : null,
                child: passenger.profileImage == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      )
                    : null,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name ?? 'unknown_passenger'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                    Text(
                      '${passenger.seatsCount} ${'seats'.tr}',
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: isPickedUp ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isPickedUp ? 'picked_up'.tr : 'waiting'.tr,
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeExtraSmall,
                  ),
                ),
              ),
              // زر تحقق OTP
              if (!isPickedUp && (passenger.carpoolTripId != null))
                IconButton(
                  icon: Icon(Icons.verified_user,
                      color: Theme.of(context).primaryColor),
                  tooltip: 'تحقق OTP',
                  onPressed: () async {
                    String? otp = await showDialog<String>(
                      context: context,
                      builder: (context) {
                        TextEditingController otpController =
                            TextEditingController();
                        return AlertDialog(
                          title: Text('تحقق OTP للراكب'),
                          content: TextField(
                            controller: otpController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'أدخل كود OTP',
                            ),
                            maxLength: 6,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('إلغاء'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(
                                    context, otpController.text.trim());
                              },
                              child: Text('تحقق'),
                            ),
                          ],
                        );
                      },
                    );
                    if (otp != null && otp.isNotEmpty) {
                      final rideController = Get.find<RideController>();
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) =>
                            Center(child: CircularProgressIndicator()),
                      );
                      final response = await rideController.matchOtp(
                          passenger.carpoolTripId!, otp);
                      Navigator.pop(context); // Close loading
                      if (response.statusCode == 200) {
                        Get.showSnackbar(GetSnackBar(
                          title: 'نجاح',
                          message: 'تم التحقق من الكود بنجاح',
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.green,
                        ));
                      } else {
                        Get.showSnackbar(GetSnackBar(
                          title: 'خطأ',
                          message: 'فشل التحقق من الكود',
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        ));
                      }
                    }
                  },
                ),
            ],
          ),
          if (!isPickedUp) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isPickupInProgress
                    ? null
                    : () => controller.pickupPassenger(passenger),
                icon: isPickupInProgress
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.check_circle, size: 16),
                label: Text(
                  isPickupInProgress ? 'picking_up'.tr : 'pickup'.tr,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ] else if (passenger.status == 'picked_up') ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => controller.dropoffPassenger(passenger),
                icon: Icon(Icons.location_on, size: 16),
                label: Text(
                  'dropoff'.tr,
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // دالة لحساب حدود الخريطة للمسار
  LatLngBounds _getBoundsForRoute(LatLng start, LatLng end) {
    double minLat = math.min(start.latitude, end.latitude);
    double maxLat = math.max(start.latitude, end.latitude);
    double minLng = math.min(start.longitude, end.longitude);
    double maxLng = math.max(start.longitude, end.longitude);

    // إضافة هامش صغير للحدود
    const double margin = 0.01; // حوالي 1 كم
    return LatLngBounds(
      southwest: LatLng(minLat - margin, minLng - margin),
      northeast: LatLng(maxLat + margin, maxLng + margin),
    );
  }

  Widget _buildPassengersPanel(CurrentTrip trip) {
    // Get all passengers from both sources
    final acceptedPassengers = trip.acceptedPassengers ?? [];
    final passengers = trip.pendingPassengers ?? [];
    final allPassengers = [...acceptedPassengers, ...passengers];

    if (allPassengers.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 16,
      left: 16,
      child: Container(
        width: 320,
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'passengers'.tr,
                    style: textBold.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeDefault,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${allPassengers.length}',
                      style: textBold.copyWith(
                        color: Colors.white,
                        fontSize: Dimensions.fontSizeSmall,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Passengers List
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: allPassengers.length,
                itemBuilder: (context, index) {
                  final passenger = allPassengers[index];
                  return _buildPassengerCard(passenger, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerCard(dynamic passenger, int index) {
    return Container(
      margin: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Passenger Header
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: _getPassengerProfileImage(passenger) != null
                    ? NetworkImage(_getPassengerProfileImage(passenger)!)
                    : null,
                child: _getPassengerProfileImage(passenger) == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: Dimensions.paddingSizeDefault),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPassengerName(passenger) ?? 'unknown_passenger'.tr,
                      style: textBold.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          color: Theme.of(context).primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_getPassengerSeats(passenger) ?? 1} ${'seats'.tr}',
                          style: textRegular.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                        const SizedBox(width: Dimensions.paddingSizeDefault),
                        Icon(
                          Icons.attach_money,
                          color: Colors.green,
                          size: 14,
                        ),
                        Text(
                          '${_getPassengerPrice(passenger)?.toStringAsFixed(2) ?? '0'} EGP',
                          style: textMedium.copyWith(
                            fontSize: Dimensions.fontSizeSmall,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color:
                      _getPassengerStatusColor(_getPassengerStatus(passenger)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getPassengerStatusText(_getPassengerStatus(passenger)),
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeExtraSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          // Pickup Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'pickup_location'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      _getPassengerPickupAddress(passenger) ??
                          (_getPassengerStartCoordinates(passenger) != null
                              ? '${_getPassengerStartCoordinates(passenger)![0].toStringAsFixed(6)}, ${_getPassengerStartCoordinates(passenger)![1].toStringAsFixed(6)}'
                              : 'unknown_location'.tr),
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          // Dropoff Location
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.flag,
                color: Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dropoff_location'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                    Text(
                      _getPassengerEndCoordinates(passenger) != null
                          ? '${_getPassengerEndCoordinates(passenger)![0].toStringAsFixed(6)}, ${_getPassengerEndCoordinates(passenger)![1].toStringAsFixed(6)}'
                          : (_getPassengerDropoffAddress(passenger) ??
                              'Dropoff location'),
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).hintColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          // OTP Section
          if (_getPassengerStatus(passenger) == 'accepted' ||
              _getPassengerStatus(passenger) == 'pending')
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Theme.of(context).primaryColor,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'otp_verification'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeSmall,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding:
                              const EdgeInsets.all(Dimensions.paddingSizeSmall),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Text(
                            _generateOTP(_getPassengerId(passenger) ?? ''),
                            style: textBold.copyWith(
                              fontSize: Dimensions.fontSizeLarge,
                              color: Theme.of(context).primaryColor,
                              letterSpacing: 2,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeSmall),
                      ElevatedButton.icon(
                        onPressed: () => _showOTPDialog(passenger),
                        icon: const Icon(Icons.verified_user, size: 16),
                        label: Text(
                          'verify'.tr,
                          style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                            vertical: Dimensions.paddingSizeExtraSmall,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Dimensions.paddingSizeSmall),
                  // Additional passenger info
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).hintColor,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ID: ${_getPassengerId(passenger)?.substring(0, 8) ?? 'N/A'}...',
                        style: textRegular.copyWith(
                          fontSize: Dimensions.fontSizeExtraSmall,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _getPassengerStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'picked_up':
        return Colors.blue;
      case 'dropped_off':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getPassengerStatusText(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'picked_up':
        return 'picked_up'.tr;
      case 'dropped_off':
        return 'dropped_off'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  String _generateOTP(String passengerId) {
    // Generate a consistent 6-digit OTP based on passenger ID
    int hash = passengerId.hashCode;
    int otp = (hash.abs() % 900000) + 100000; // 6-digit number
    return otp.toString();
  }

  // Helper methods to get passenger data regardless of type
  String? _getPassengerId(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.carpoolTripId;
    } else if (passenger is Passenger) {
      return passenger.carpoolPassengerId?.toString();
    }
    return null;
  }

  String? _getPassengerName(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.name;
    } else if (passenger is Passenger) {
      return passenger.name;
    }
    return null;
  }

  String? _getPassengerStatus(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.status;
    } else if (passenger is Passenger) {
      return 'pending'; // Default status for Passenger type
    }
    return null;
  }

  int? _getPassengerSeats(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.seatsCount;
    } else if (passenger is Passenger) {
      return passenger.seatsCount;
    }
    return null;
  }

  double? _getPassengerPrice(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.price;
    } else if (passenger is Passenger) {
      return passenger.fare;
    }
    return null;
  }

  String? _getPassengerPickupAddress(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.pickupAddress;
    } else if (passenger is Passenger) {
      return passenger.pickupAddress;
    }
    return null;
  }

  String? _getPassengerDropoffAddress(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.dropoffAddress;
    } else if (passenger is Passenger) {
      return passenger.dropoffAddress;
    }
    return null;
  }

  List<double>? _getPassengerStartCoordinates(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.startCoordinates;
    } else if (passenger is Passenger) {
      return passenger.startCoordinates;
    }
    return null;
  }

  List<double>? _getPassengerEndCoordinates(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.endCoordinates;
    } else if (passenger is Passenger) {
      return passenger.endCoordinates;
    }
    return null;
  }

  String? _getPassengerProfileImage(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.profileImage;
    } else if (passenger is Passenger) {
      return passenger.profileImage;
    }
    return null;
  }

  void _showOTPDialog(dynamic passenger) {
    final otp = _generateOTP(_getPassengerId(passenger) ?? '');

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text('otp_verification'.tr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'passenger_name'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            Text(
              _getPassengerName(passenger) ?? 'unknown_passenger'.tr,
              style: textBold.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'otp_code'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).primaryColor,
                ),
              ),
              child: Text(
                otp,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeExtraLarge,
                  color: Theme.of(context).primaryColor,
                  letterSpacing: 4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'otp_instructions'.tr,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.3),
                ),
              ),
              child: Text(
                'Share this OTP with the passenger for verification',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.orange,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Passenger ID: ${_getPassengerId(passenger) ?? 'N/A'}',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Status: ${_getPassengerStatus(passenger) ?? 'Unknown'}',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'Seats: ${_getPassengerSeats(passenger) ?? 1}',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.showSnackbar(GetSnackBar(
                title: 'otp_verified'.tr,
                message: '${'passenger'.tr}: ${_getPassengerName(passenger)}',
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ),
            child: Text('verify_otp'.tr),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy OTP to clipboard
              Clipboard.setData(ClipboardData(text: otp));
              Get.back();
              Get.showSnackbar(GetSnackBar(
                title: 'otp_copied'.tr,
                message: 'OTP copied to clipboard',
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
            child: Text('copy_otp'.tr),
          ),
        ],
      ),
    );
  }
}
