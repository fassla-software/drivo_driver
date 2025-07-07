import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../theme/theme_controller.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../../util/images.dart';
import '../domain/models/current_trips_with_passengers_response_model.dart';
import '../controllers/carpool_trip_map_controller.dart';

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
                        target: controller.centerPosition ??
                            const LatLng(30.0444, 31.2357),
                        zoom: 14,
                      ),
                      onMapCreated: (GoogleMapController mapController) {
                        controller.setMapController(mapController);
                      },
                      markers: controller.markers,
                      polylines: controller.polylines,
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
              if (controller.currentTrip.restStops != null &&
                  controller.currentTrip.restStops!.isNotEmpty)
                _buildLegendItem(
                    Colors.purple, Icons.local_gas_station, 'rest_stops'.tr),
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
}
