import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/carpool_routes_controller.dart';
import '../domain/models/carpool_routes_response_model.dart';
import 'all_trips_passengers.dart';
import 'my_current_trips.dart';
import 'register_route_screen.dart';

class AllTripsScreen extends StatefulWidget {
  const AllTripsScreen({super.key});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      Get.find<CarpoolRoutesController>().loadMoreCarpoolRoutes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBarWidget(
        title: 'All Trips',
        showBackButton: true,
      ),
      body: GetBuilder<CarpoolRoutesController>(
        builder: (controller) {
          return Column(
            children: [
              // Header Section
              _buildHeaderSection(controller),

              // Action Buttons Section
              _buildActionButtonsSection(),

              // Content Section
              Expanded(
                child: _buildContentSection(controller),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(CarpoolRoutesController controller) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.1),
            Theme.of(context).primaryColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Carpool Routes',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeExtraLarge,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                Text(
                  controller.isLoading
                      ? 'Loading routes...'
                      : 'Total routes: ${controller.totalRoutesCount}',
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Row(
        children: [
          // My Current Trips Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const MyCurrentTripsScreen());
              },
              icon: const Icon(Icons.my_location, size: 20),
              label: Text(
                'My Current Trips',
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeDefault,
                  horizontal: Dimensions.paddingSizeSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
                elevation: 2,
              ),
            ),
          ),

          const SizedBox(width: Dimensions.paddingSizeDefault),

          // Register Route Button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                Get.to(() => const RegisterRouteScreen());
              },
              icon: const Icon(Icons.add_road, size: 20),
              label: Text(
                'Register Route',
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: Dimensions.paddingSizeDefault,
                  horizontal: Dimensions.paddingSizeSmall,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeSmall),
                ),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection(CarpoolRoutesController controller) {
    if (controller.isLoading && controller.carpoolRoutes.isEmpty) {
      return _buildLoadingWidget();
    }

    if (controller.carpoolRoutes.isEmpty && !controller.isLoading) {
      return _buildEmptyWidget();
    }

    return RefreshIndicator(
      onRefresh: controller.refreshCarpoolRoutes,
      color: Theme.of(context).primaryColor,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
        itemCount: controller.carpoolRoutes.length +
            (controller.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == controller.carpoolRoutes.length) {
            return _buildLoadMoreWidget();
          }

          final route = controller.carpoolRoutes[index];
          return _buildRouteCard(route, controller);
        },
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
          Text(
            'Loading carpool routes...',
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 80,
            color: Theme.of(context).hintColor.withOpacity(0.5),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'No carpool routes found',
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'Check back later for available routes',
            textAlign: TextAlign.center,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          ElevatedButton.icon(
            onPressed: () {
              Get.find<CarpoolRoutesController>().refreshCarpoolRoutes();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge,
                vertical: Dimensions.paddingSizeDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreWidget() {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildRouteCard(
      CarpoolRoute route, CarpoolRoutesController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
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
        children: [
          // Header with driver info
          _buildRouteHeader(route),

          // Route details
          _buildRouteDetails(route),

          // Vehicle features
          _buildVehicleFeatures(route, controller),

          // Passengers section
          if (controller.routeHasPassengers(route))
            _buildPassengersSection(route),

          // Footer with actions
          _buildRouteFooter(route, controller),
        ],
      ),
    );
  }

  Widget _buildRouteHeader(CarpoolRoute route) {
    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(Dimensions.paddingSizeDefault),
          topRight: Radius.circular(Dimensions.paddingSizeDefault),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).primaryColor,
            backgroundImage:
                route.profileImage != null && route.profileImage!.isNotEmpty
                    ? NetworkImage(route.profileImage!)
                    : null,
            child: route.profileImage == null || route.profileImage!.isEmpty
                ? const Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 30,
                  )
                : null,
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name ?? 'Unknown Driver',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeLarge,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.directions_car,
                      size: 16,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      route.vehicleName ?? 'Unknown Vehicle',
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius:
                  BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            ),
            child: Text(
              '${route.seats} seats',
              style: textMedium.copyWith(
                color: Colors.white,
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteDetails(CarpoolRoute route) {
    return Padding(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Departure info
          Row(
            children: [
              Icon(
                Icons.schedule,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              Text(
                '${route.startDay} • ${route.startHour}',
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Route addresses
          Column(
            children: [
              _buildAddressRow(
                Icons.play_arrow,
                Colors.green,
                'From',
                route.startAddress ?? 'Unknown location',
              ),
              const SizedBox(height: Dimensions.paddingSizeSmall),
              _buildAddressRow(
                Icons.flag,
                Colors.red,
                'To',
                route.endAddress ?? 'Unknown location',
              ),
            ],
          ),

          const SizedBox(height: Dimensions.paddingSizeDefault),

          // Age and gender restrictions
          Row(
            children: [
              _buildInfoChip(
                Icons.people,
                '${route.allowedAgeMin}-${route.allowedAgeMax} years',
              ),
              const SizedBox(width: Dimensions.paddingSizeSmall),
              _buildInfoChip(
                Icons.person,
                route.allowedGender ?? 'both',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
      IconData icon, Color iconColor, String label, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 20,
        ),
        const SizedBox(width: Dimensions.paddingSizeSmall),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeSmall,
                  color: Theme.of(context).hintColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: textRegular.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
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

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Dimensions.paddingSizeSmall,
        vertical: Dimensions.paddingSizeExtraSmall,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context).primaryColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeExtraSmall,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleFeatures(
      CarpoolRoute route, CarpoolRoutesController controller) {
    final features = controller.getRouteFeatures(route);

    if (features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vehicle Features',
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Wrap(
            spacing: Dimensions.paddingSizeSmall,
            runSpacing: Dimensions.paddingSizeSmall,
            children: features.map((feature) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Dimensions.paddingSizeSmall,
                  vertical: Dimensions.paddingSizeExtraSmall,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius:
                      BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
                child: Text(
                  feature,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeExtraSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
      ),
    );
  }

  Widget _buildPassengersSection(CarpoolRoute route) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: Dimensions.paddingSizeLarge),
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
                'Passengers (${route.passengersCount})',
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: route.passengers?.length ?? 0,
            itemBuilder: (context, index) {
              final passenger = route.passengers![index];
              return _buildPassengerItem(passenger);
            },
          ),
          const SizedBox(height: Dimensions.paddingSizeDefault),
        ],
      ),
    );
  }

  Widget _buildPassengerItem(Passenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
            backgroundImage: passenger.profileImage != null &&
                    passenger.profileImage!.isNotEmpty
                ? NetworkImage(passenger.profileImage!)
                : null,
            child: passenger.profileImage == null ||
                    passenger.profileImage!.isEmpty
                ? Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: Dimensions.paddingSizeDefault),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  passenger.name ?? 'Unknown Passenger',
                  style: textMedium.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                if (passenger.fare != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    '${passenger.fare} EGP',
                    style: textRegular.copyWith(
                      fontSize: Dimensions.fontSizeSmall,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeSmall,
              vertical: Dimensions.paddingSizeExtraSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius:
                  BorderRadius.circular(Dimensions.paddingSizeExtraSmall),
            ),
            child: Text(
              '${passenger.seatsCount} seats',
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeExtraSmall,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteFooter(
      CarpoolRoute route, CarpoolRoutesController controller) {
    final availableSeats = controller.getAvailableSeats(route);

    return Container(
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(Dimensions.paddingSizeDefault),
          bottomRight: Radius.circular(Dimensions.paddingSizeDefault),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Seats',
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$availableSeats seats',
                  style: textBold.copyWith(
                    fontSize: Dimensions.fontSizeDefault,
                    color: availableSeats > 0
                        ? Theme.of(context).primaryColor
                        : Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Navigate to passengers screen
              Get.to(() => AllTripsPassengersScreen(trip: route));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeLarge,
                vertical: Dimensions.paddingSizeSmall,
              ),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(Dimensions.paddingSizeSmall),
              ),
            ),
            child: Text(
              route.passengersCount != null && route.passengersCount! > 0
                  ? 'View Passengers (${route.passengersCount})'
                  : 'View Details',
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteDetailsDialog(CarpoolRoute route) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: Dimensions.paddingSizeSmall),
            const Text('Route Details'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Driver Name', route.name ?? 'Unknown'),
                _buildDetailRow('Vehicle', route.vehicleName ?? 'Unknown'),
                _buildDetailRow(
                    'Departure', '${route.startDay} ${route.startHour}'),
                _buildDetailRow('Total Seats', '${route.seats}'),
                _buildDetailRow('Passengers', '${route.passengersCount ?? 0}'),
                _buildDetailRow('Age Range',
                    '${route.allowedAgeMin}-${route.allowedAgeMax}'),
                _buildDetailRow('Gender', route.allowedGender ?? 'both'),
                const SizedBox(height: Dimensions.paddingSizeDefault),
                Text(
                  'Route Path',
                  style:
                      textBold.copyWith(fontSize: Dimensions.fontSizeDefault),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'From: ${route.startAddress ?? 'Unknown'}',
                  style:
                      textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
                const SizedBox(height: Dimensions.paddingSizeSmall),
                Text(
                  'To: ${route.endAddress ?? 'Unknown'}',
                  style:
                      textRegular.copyWith(fontSize: Dimensions.fontSizeSmall),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Dimensions.paddingSizeSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: textMedium.copyWith(
                fontSize: Dimensions.fontSizeSmall,
                color: Theme.of(context).hintColor,
              ),
            ),
          ),
          const SizedBox(width: Dimensions.paddingSizeSmall),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: textRegular.copyWith(
                fontSize: Dimensions.fontSizeSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
