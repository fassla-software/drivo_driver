import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/current_trips_controller.dart';
import '../domain/models/current_trips_with_passengers_response_model.dart';
import '../domain/models/carpool_routes_response_model.dart';
import 'carpool_trip_map_screen.dart';

class MyCurrentTripsScreen extends StatefulWidget {
  const MyCurrentTripsScreen({super.key});

  @override
  State<MyCurrentTripsScreen> createState() => _MyCurrentTripsScreenState();
}

class _MyCurrentTripsScreenState extends State<MyCurrentTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CurrentTripsController controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get or create the controller
    try {
      controller = Get.find<CurrentTripsController>();
      print('=== Controller found: $controller ===');
    } catch (e) {
      print('=== Controller not found, creating new one: $e ===');
      controller = Get.put(CurrentTripsController(
        currentTripsServiceInterface: Get.find(),
      ));
    }

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== Loading data in postFrameCallback ===');
      controller.getCurrentTripsWithPassengers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'my_current_trips'.tr,
        showBackButton: true,
      ),
      body: GetBuilder<CurrentTripsController>(
        init: controller,
        builder: (ctrl) {
          print(
              '=== UI Building with controller, isLoading: ${ctrl.isLoading}, trips count: ${ctrl.currentTrips.length} ===');

          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Statistics Cards
              _buildStatisticsSection(ctrl),

              // Tab Bar
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeLarge,
                ),
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
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Theme.of(context).primaryColor,
                  unselectedLabelColor: Theme.of(context).hintColor,
                  indicatorColor: Theme.of(context).primaryColor,
                  indicatorWeight: 3,
                  labelStyle: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  unselectedLabelStyle: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                  ),
                  tabs: [
                    Tab(text: 'pending'.tr),
                    Tab(text: 'ongoing'.tr),
                    Tab(text: 'completed'.tr),
                  ],
                ),
              ),

              // Tab Bar View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTripsListView(ctrl, ctrl.pendingTripsList),
                    _buildTripsListView(ctrl, ctrl.ongoingTripsList),
                    _buildTripsListView(ctrl, ctrl.completedTripsList),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatisticsSection(CurrentTripsController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Text(
            value,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: color,
            ),
          ),
          Text(
            title,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEarningsCard(CurrentTripsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet,
              color: Colors.white, size: 32),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'total_earnings'.tr,
                  style: textRegular.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                Text(
                  '${(controller.totalEarnings).toStringAsFixed(2)} EGP',
                  style: textBold.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeExtraLarge,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripsListView(
      CurrentTripsController controller, List<CurrentTrip> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Text(
              'no_trips_found'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeLarge,
                color: Theme.of(context).hintColor,
              ),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'no_trips_description'.tr,
              style: textRegular.copyWith(
                color: Theme.of(context).hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => controller.refreshCurrentTrips(),
      child: ListView.builder(
        padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          return _buildTripCard(controller, trip, index);
        },
      ),
    );
  }

  Widget _buildTripCard(
      CurrentTripsController controller, CurrentTrip trip, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Header
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: controller
                  .getTripStatusColor(trip.tripStatus)
                  .withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(Dimensions.paddingSizeDefault),
                topRight: Radius.circular(Dimensions.paddingSizeDefault),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'trip_id'.tr,
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          Text(
                            ' #${trip.id}',
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 16,
                            color: Theme.of(context).hintColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${controller.getFormattedStartDate(trip)} • ${controller.getFormattedStartTime(trip)}',
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            controller.getTripDurationText(trip),
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeSmall,
                              color: Theme.of(context).hintColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: Dimensions.paddingSizeSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeSmall,
                    vertical: 4,
                  ),
                  child: Text(
                    controller.getTripStatusDisplayText(trip.tripStatus),
                    style: textMedium.copyWith(
                      color: Colors.white,
                      fontSize: Dimensions.fontSizeExtraSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route Information
                _buildRouteSection(trip),

                const SizedBox(height: Dimensions.paddingSizeDefault),

                // Trip Details
                _buildTripDetailsSection(controller, trip),

                // لا تعرض الركاب إذا كانت القائمة فارغة
                if (controller.tripHasPassengers(trip) ||
                    (trip.pendingPassengers != null &&
                        trip.pendingPassengers!.isNotEmpty)) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _buildPassengersSection(controller, trip),
                ],

                // Start Trip Button for Pending Trips
                if (controller.getTripStatus(trip) == 'pending') ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => controller.startTrip(trip.id ?? 0),
                      icon: const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(
                        'Start Trip',
                        style: textMedium.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              Dimensions.paddingSizeSmall),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],

                // Show Map Button for Ongoing Trips
                if (controller.getTripStatus(trip) == 'ongoing') ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // تحقق من وجود إحداثيات قبل فتح الخريطة
                        if (trip.startCoordinates != null &&
                            trip.endCoordinates != null) {
                          Get.to(() => CarpoolTripMapScreen(trip: trip));
                        } else {
                          Get.showSnackbar(GetSnackBar(
                            title: 'خطأ',
                            message: 'لا توجد إحداثيات للمسار',
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ));
                        }
                      },
                      icon: const Icon(Icons.map, color: Colors.white),
                      label: Text(
                        'View Trip',
                        style: textMedium.copyWith(
                          color: Colors.white,
                          fontSize: Dimensions.fontSizeDefault,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: Dimensions.paddingSizeDefault,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                              Dimensions.paddingSizeSmall),
                        ),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],

                // Show Trip Path Button for Completed Trips
                if (trip.tripStatus == 'completed') ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _buildShowTripPathButton(trip),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(CurrentTrip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.my_location,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                trip.startAddress ?? 'unknown_location'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Container(
          margin: const EdgeInsets.only(left: 10),
          height: 20,
          width: 2,
          color: Theme.of(context).primaryColor.withOpacity(0.3),
        ),
        Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.red,
              size: 20,
            ),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            Expanded(
              child: Text(
                trip.endAddress ?? 'unknown_location'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTripDetailsSection(
      CurrentTripsController controller, CurrentTrip trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'available_seats'.tr,
                  '${controller.getAvailableSeats(trip)}',
                  Icons.airline_seat_recline_normal,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              Expanded(
                child: _buildDetailItem(
                  'passengers'.tr,
                  '${trip.totalAcceptedPassengers}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'total_fare'.tr,
                  '${trip.price?.toStringAsFixed(2) ?? '0'} EGP',
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          if (trip.vehicleInfo != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildVehicleInfo(trip.vehicleInfo!),
          ],
          if (trip.routePreferences != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildRouteFeatures(controller, trip),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(
          title,
          style: textRegular.copyWith(
            fontSize: Dimensions.fontSizeExtraSmall,
            color: Theme.of(context).hintColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildVehicleInfo(VehicleInfo vehicleInfo) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(
            Icons.directions_car,
            color: Theme.of(context).primaryColor,
            size: 20,
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            child: Text(
              '${vehicleInfo.brand ?? ''} ${vehicleInfo.model ?? ''}',
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
          if (vehicleInfo.plateNumber != null)
            Text(
              vehicleInfo.plateNumber!,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteFeatures(
      CurrentTripsController controller, CurrentTrip trip) {
    final features = controller.getRouteFeatures(trip);
    if (features.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'features'.tr,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeSmall,
            color: Theme.of(context).hintColor,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: features
              .map((feature) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      feature,
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeExtraSmall,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildPassengersSection(
      CurrentTripsController controller, CurrentTrip trip) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'accepted_passengers'.tr,
          style: textMedium.copyWith(
            fontSize: Dimensions.fontSizeDefault,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: Dimensions.paddingSizeSmall),
        ...(trip.acceptedPassengers ?? [])
            .map((passenger) => _buildPassengerCard(controller, passenger))
            .toList(),
        ...(trip.pendingPassengers ?? [])
            .map((passenger) => _buildPassengerCard(controller, passenger))
            .toList(),
      ],
    );
  }

  Widget _buildPassengerCard(
      CurrentTripsController controller, dynamic passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      )
                    : null,
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
                            _getPassengerName(passenger) ??
                                'unknown_passenger'.tr,
                            style: textMedium.copyWith(
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeSmall,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: controller.getPassengerStatusColor(
                                _getPassengerStatus(passenger)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            controller.getPassengerStatusDisplayText(
                                _getPassengerStatus(passenger)),
                            style: textMedium.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeExtraSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_getPassengerSeats(passenger)} ${'seats'.tr}',
                      style: textRegular.copyWith(
                        fontSize: Dimensions.fontSizeSmall,
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          // تفاصيل إضافية للراكب
          _buildDetailRow('عدد المقاعد', '${_getPassengerSeats(passenger)}'),
          if (_getPassengerPickupAddress(passenger) != null)
            _buildDetailRow(
                'عنوان الاستلام', _getPassengerPickupAddress(passenger)!),
          if (_getPassengerDropoffAddress(passenger) != null)
            _buildDetailRow(
                'عنوان النزول', _getPassengerDropoffAddress(passenger)!),
          _buildDetailRow('السعر',
              '${_getPassengerPrice(passenger)?.toStringAsFixed(2) ?? '0'} EGP'),
          _buildDetailRow(
              'الحالة',
              controller.getPassengerStatusDisplayText(
                  _getPassengerStatus(passenger))),
          if (_getPassengerId(passenger) != null)
            _buildDetailRow('Trip ID', _getPassengerId(passenger)!),
        ],
      ),
    );
  }

  Widget _buildAddressSection(
      String title, String address, IconData icon, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeExtraSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              Text(
                address,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Rest stops section removed as it's not available in new API structure

  Widget _buildStartTripButton(
      CurrentTripsController controller, CurrentTrip trip) {
    final bool isStarting = controller.isTripBeingStarted(trip.id ?? 0);

    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isStarting || trip.id == null
            ? null
            : () => controller.startTrip(trip.id!),
        icon: isStarting
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(Icons.play_arrow, color: Colors.white),
        label: Text(
          isStarting ? 'starting_trip'.tr : 'start_trip'.tr,
          style: textMedium.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildShowMapButton(CurrentTrip trip) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Get.to(() => CarpoolTripMapScreen(trip: trip));
        },
        icon: Icon(Icons.map, color: Colors.white),
        label: Text(
          'view_trip'.tr,
          style: textMedium.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildShowTripPathButton(CurrentTrip trip) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Navigate to trip path screen
          Get.showSnackbar(GetSnackBar(
            title: 'info'.tr,
            message: 'trip_path_feature_coming_soon'.tr,
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.blue,
          ));
        },
        icon: Icon(Icons.route, color: Colors.white),
        label: Text(
          'show_trip_path'.tr,
          style: textMedium.copyWith(
            color: Colors.white,
            fontSize: Dimensions.fontSizeDefault,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: Dimensions.paddingSizeDefault,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
          ),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: textMedium.copyWith(fontSize: 14)),
          Expanded(
              child: Text(value, style: textRegular.copyWith(fontSize: 14))),
        ],
      ),
    );
  }

  // Helper methods to get passenger data regardless of type
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

  String? _getPassengerProfileImage(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.profileImage;
    } else if (passenger is Passenger) {
      return passenger.profileImage;
    }
    return null;
  }

  String? _getPassengerId(dynamic passenger) {
    if (passenger is AcceptedPassenger) {
      return passenger.carpoolTripId;
    } else if (passenger is Passenger) {
      return passenger.carpoolPassengerId?.toString();
    }
    return null;
  }
}
