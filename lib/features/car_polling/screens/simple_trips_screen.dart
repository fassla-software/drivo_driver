import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/simple_trips_controller.dart';
import '../domain/models/simple_trip_model.dart';
import '../domain/models/simple_passenger_model.dart';
import 'simple_trip_map_screen.dart';

class SimpleTripsScreen extends StatefulWidget {
  const SimpleTripsScreen({super.key});

  @override
  State<SimpleTripsScreen> createState() => _SimpleTripsScreenState();
}

class _SimpleTripsScreenState extends State<SimpleTripsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late SimpleTripsController controller;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    // Get or create the controller
    try {
      controller = Get.find<SimpleTripsController>();
      print('=== SimpleTripsController found: $controller ===');
    } catch (e) {
      print('=== SimpleTripsController not found, creating new one: $e ===');
      controller = Get.put(SimpleTripsController(
        currentTripsServiceInterface: Get.find(),
      ));
    }

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('=== Loading data in postFrameCallback ===');
      controller.getCurrentTrips();
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
      body: GetBuilder<SimpleTripsController>(
        init: controller,
        builder: (ctrl) {
          print(
              '=== UI Building with controller, isLoading: ${ctrl.isLoading}, trips count: ${ctrl.trips.length} ===');

          if (ctrl.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return (controller.isStartingTrip || controller.isEndingTrip)
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator.adaptive(),
                      const SizedBox(height: Dimensions.paddingSizeDefault),
                      Text(
                        controller.isStartingTrip
                            ? 'starting_trip'.tr
                            : 'ending'.tr,
                        style: textMedium.copyWith(
                          fontSize: Dimensions.fontSizeDefault,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Tab Bar
                    Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: Dimensions.paddingSizeLarge,
                        vertical: Dimensions.paddingSizeDefault,
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
                          _buildTripsListView(ctrl, ctrl.pendingTrips),
                          _buildTripsListView(ctrl, ctrl.ongoingTrips),
                          _buildTripsListView(ctrl, ctrl.completedTrips),
                        ],
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildTripsListView(
      SimpleTripsController controller, List<SimpleTripModel> trips) {
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
      onRefresh: () => controller.refreshTrips(),
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
      SimpleTripsController controller, SimpleTripModel trip, int index) {
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
                            '${trip.formattedStartDate} • ${trip.formattedStartTime}',
                            style: textRegular.copyWith(
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
                  decoration: BoxDecoration(
                    color: controller.getTripStatusColor(trip.tripStatus),
                    borderRadius: BorderRadius.circular(12),
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

                // Passengers Section
                if (trip.passengers != null && trip.passengers!.isNotEmpty) ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  _buildPassengersSection(trip),
                ],

                // Start Trip Button for Pending Trips
                if (trip.tripStatus == 'pending') ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: controller.isTripBeingStarted(trip.id ?? 0)
                          ? null
                          : () => controller.startTrip(trip.id ?? 0),
                      icon: controller.isTripBeingStarted(trip.id ?? 0)
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.play_arrow, color: Colors.white),
                      label: Text(
                        controller.isTripBeingStarted(trip.id ?? 0)
                            ? 'starting_trip'.tr
                            : 'start_trip'.tr,
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
                if (trip.tripStatus == 'ongoing') ...[
                  const SizedBox(height: Dimensions.paddingSizeDefault),
                  Row(
                    children: [
                      // View Trip Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isTripBeingEnded(trip.id ?? 0)
                              ? null
                              : () {
                                  print(
                                      '=== Opening map for trip ID: ${trip.id} ===');
                                  print(
                                      '=== Trip passenger coordinates: ${trip.passengerCoordinates?.length ?? 0} ===');
                                  print(
                                      '=== Trip passengers: ${trip.passengers?.length ?? 0} ===');

                                  if (trip.startCoordinates != null &&
                                      trip.endCoordinates != null) {
                                    Get.to(
                                        () => SimpleTripMapScreen(trip: trip));
                                  } else {
                                    Get.showSnackbar(GetSnackBar(
                                      title: 'خطأ',
                                      message: 'لا توجد إحداثيات للمسار',
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.red,
                                    ));
                                  }
                                },
                          icon: controller.isTripBeingEnded(trip.id ?? 0)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.map, color: Colors.white),
                          label: Text(
                            controller.isTripBeingEnded(trip.id ?? 0)
                                ? 'ending'.tr
                                : 'show_map'.tr,
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
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      // End Trip Button
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: controller.isTripBeingEnded(trip.id ?? 0)
                              ? null
                              : () => _showEndTripConfirmationDialog(
                                  controller, trip),
                          icon: controller.isTripBeingEnded(trip.id ?? 0)
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : const Icon(Icons.stop, color: Colors.white),
                          label: Text(
                            controller.isTripBeingEnded(trip.id ?? 0)
                                ? 'ending'.tr
                                : 'end_trip'.tr,
                            style: textMedium.copyWith(
                              color: Colors.white,
                              fontSize: Dimensions.fontSizeDefault,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
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
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteSection(SimpleTripModel trip) {
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
      SimpleTripsController controller, SimpleTripModel trip) {
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
              Expanded(
                child: _buildDetailItem(
                  'passengers'.tr,
                  '${trip.passengersCount ?? 0}',
                  Icons.people,
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'price'.tr,
                  trip.formattedPrice,
                  Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
          if (trip.vehicleName != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildVehicleInfo(trip),
          ],
          if (trip.features.isNotEmpty) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            _buildRouteFeatures(trip),
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

  Widget _buildVehicleInfo(SimpleTripModel trip) {
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
              trip.vehicleName ?? 'unknown_vehicle'.tr,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFeatures(SimpleTripModel trip) {
    final features = trip.features;
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

  Widget _buildPassengersSection(SimpleTripModel trip) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border:
            Border.all(color: Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'passengers'.tr,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${trip.passengers!.length}',
                  style: textMedium.copyWith(
                    color: Colors.white,
                    fontSize: Dimensions.fontSizeExtraSmall,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          ...trip.passengers!
              .map((passenger) => _buildPassengerCard(passenger))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(SimplePassengerModel passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          // Passenger Header
          Row(
            children: [
              // Profile Image
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    Theme.of(context).primaryColor.withOpacity(0.1),
                backgroundImage: passenger.profileImage != null
                    ? NetworkImage(passenger.profileImage!)
                    : null,
                child: passenger.profileImage == null
                    ? Icon(
                        Icons.person,
                        color: Theme.of(context).primaryColor,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),

              // Passenger Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      passenger.name ?? 'unknown_passenger'.tr,
                      style: textMedium.copyWith(
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.event_seat,
                          color: Theme.of(context).primaryColor,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${passenger.seatsCount ?? 1} ${'seats'.tr}',
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
                          passenger.formattedFare,
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: passenger.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: passenger.statusColor),
                ),
                child: Text(
                  passenger.statusDisplayText,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: passenger.statusColor,
                  ),
                ),
              ),
            ],
          ),

          // Pickup and Dropoff Locations
          if (passenger.pickupAddress != null ||
              passenger.dropoffAddress != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Container(
              padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
              ),
              child: Column(
                children: [
                  if (passenger.pickupAddress != null) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.green,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            passenger.pickupAddress!,
                            style: textRegular.copyWith(
                              fontSize: Dimensions.fontSizeExtraSmall,
                              color: Theme.of(context).hintColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (passenger.dropoffAddress != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              passenger.dropoffAddress!,
                              style: textRegular.copyWith(
                                fontSize: Dimensions.fontSizeExtraSmall,
                                color: Theme.of(context).hintColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ],

          // Contact Info
          if (passenger.phone != null || passenger.email != null) ...[
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Row(
              children: [
                if (passenger.phone != null) ...[
                  Icon(
                    Icons.phone,
                    color: Theme.of(context).primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    passenger.phone!,
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
                if (passenger.phone != null && passenger.email != null) ...[
                  const SizedBox(width: Dimensions.paddingSizeDefault),
                ],
                if (passenger.email != null) ...[
                  Icon(
                    Icons.email,
                    color: Theme.of(context).primaryColor,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    passenger.email!,
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeExtraSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Show confirmation dialog for ending trip
  void _showEndTripConfirmationDialog(
      SimpleTripsController controller, SimpleTripModel trip) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 24,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                'end_trip'.tr,
                style: textBold.copyWith(
                  fontSize: Dimensions.fontSizeLarge,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'are_you_sure_end_trip'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'Trip ID: #${trip.id}',
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              Text(
                'this_action_cannot_be_undone'.tr,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr,
                style: textMedium.copyWith(
                  color: Theme.of(context).hintColor,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.endTrip(trip.id ?? 0);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'end_trip'.tr,
                style: textMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
