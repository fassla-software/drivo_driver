import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../common_widgets/app_bar_widget.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../controllers/passenger_review_controller.dart';
import '../domain/models/carpool_routes_response_model.dart';

class AllTripsPassengersScreen extends StatefulWidget {
  final CarpoolRoute trip;

  const AllTripsPassengersScreen({
    super.key,
    required this.trip,
  });

  @override
  State<AllTripsPassengersScreen> createState() =>
      _AllTripsPassengersScreenState();
}

class _AllTripsPassengersScreenState extends State<AllTripsPassengersScreen> {
  late PassengerReviewController _passengerReviewController;

  @override
  void initState() {
    super.initState();
    _passengerReviewController = Get.find<PassengerReviewController>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarWidget(
        title: 'trip_passengers'.tr,
        showBackButton: true,
      ),
      body: Column(
        children: [
          // Trip Info Header
          _buildTripInfoHeader(),

          // Passengers List
          Expanded(
            child: widget.trip.passengers?.isNotEmpty == true
                ? ListView.builder(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
                    itemCount: widget.trip.passengers!.length,
                    itemBuilder: (context, index) {
                      final passenger = widget.trip.passengers![index];
                      return _buildPassengerCard(passenger);
                    },
                  )
                : _buildEmptyState(),
          ),
        ],
      ),
    );
  }

  Widget _buildTripInfoHeader() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'trip_details'.tr,
            style: textBold.copyWith(
              fontSize: Dimensions.fontSizeExtraLarge,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Text(
                widget.trip.vehicleName ?? 'unknown_vehicle'.tr,
                style: textMedium.copyWith(
                  fontSize: Dimensions.fontSizeDefault,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  widget.trip.startAddress ?? 'unknown_location'.tr,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: Dimensions.paddingSizeExtraSmall),
          Row(
            children: [
              Icon(
                Icons.flag,
                color: Colors.red,
                size: 20,
              ),
              const SizedBox(width: Dimensions.paddingSizeExtraSmall),
              Expanded(
                child: Text(
                  widget.trip.endAddress ?? 'unknown_location'.tr,
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (widget.trip.startDay != null ||
              widget.trip.startHour != null) ...[
            const SizedBox(height: Dimensions.paddingSizeExtraSmall),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  color: Theme.of(context).hintColor,
                  size: 20,
                ),
                const SizedBox(width: Dimensions.paddingSizeExtraSmall),
                Text(
                  '${widget.trip.startDay ?? ''} ${widget.trip.startHour ?? ''}',
                  style: textRegular.copyWith(
                    fontSize: Dimensions.fontSizeSmall,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPassengerCard(Passenger passenger) {
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
        children: [
          // Passenger Header
          Container(
            padding: const EdgeInsets.all(Dimensions.paddingSizeLarge),
            child: Row(
              children: [
                // Profile Image
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                  backgroundImage: passenger.profileImage != null
                      ? NetworkImage(passenger.profileImage!)
                      : null,
                  child: passenger.profileImage == null
                      ? Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                          size: 30,
                        )
                      : null,
                ),

                const SizedBox(width: Dimensions.paddingSizeDefault),

                // Passenger Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passenger.name ?? 'unknown_passenger'.tr,
                        style: textBold.copyWith(
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                      const SizedBox(height: Dimensions.paddingSizeExtraSmall),
                      Row(
                        children: [
                          Icon(
                            Icons.event_seat,
                            color: Theme.of(context).primaryColor,
                            size: 16,
                          ),
                          const SizedBox(
                              width: Dimensions.paddingSizeExtraSmall),
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
                            size: 16,
                          ),
                          Text(
                            '${passenger.fare ?? 0} ${'egp'.tr}',
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
              ],
            ),
          ),

          // Pickup and Dropoff Locations
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Dimensions.paddingSizeLarge,
              vertical: Dimensions.paddingSizeSmall,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(Dimensions.paddingSizeDefault),
                bottomRight: Radius.circular(Dimensions.paddingSizeDefault),
              ),
            ),
            child: Column(
              children: [
                // Pickup Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.green,
                      size: 18,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
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
                          const SizedBox(height: 2),
                          Text(
                            passenger.pickupAddress ?? 'unknown_location'.tr,
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

                // Dropoff Location
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flag,
                      color: Colors.red,
                      size: 18,
                    ),
                    const SizedBox(width: Dimensions.paddingSizeSmall),
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
                          const SizedBox(height: 2),
                          Text(
                            passenger.dropoffAddress ?? 'unknown_location'.tr,
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

                const SizedBox(height: Dimensions.paddingSizeLarge),

                // Accept/Reject Buttons
                GetBuilder<PassengerReviewController>(
                  builder: (controller) {
                    return Row(
                      children: [
                        // Reject Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading
                                ? null
                                : () => _rejectPassenger(passenger),
                            icon: const Icon(Icons.close, color: Colors.white),
                            label: Text(
                              'reject'.tr,
                              style: textMedium.copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeDefault,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeSmall,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: Dimensions.paddingSizeDefault),

                        // Accept Button
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: controller.isLoading
                                ? null
                                : () => _acceptPassenger(passenger),
                            icon: const Icon(Icons.check, color: Colors.white),
                            label: Text(
                              'accept'.tr,
                              style: textMedium.copyWith(color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                vertical: Dimensions.paddingSizeDefault,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeSmall,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            color: Theme.of(context).hintColor,
            size: 80,
          ),
          const SizedBox(height: Dimensions.paddingSizeLarge),
          Text(
            'no_passengers_found'.tr,
            style: textMedium.copyWith(
              fontSize: Dimensions.fontSizeLarge,
              color: Theme.of(context).hintColor,
            ),
          ),
          const SizedBox(height: Dimensions.paddingSizeSmall),
          Text(
            'no_passengers_have_booked_this_trip_yet'.tr,
            style: textRegular.copyWith(
              fontSize: Dimensions.fontSizeDefault,
              color: Theme.of(context).hintColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _acceptPassenger(Passenger passenger) async {
    if (passenger.carpoolPassengerId == null) {
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'invalid_passenger_data'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    final success = await _passengerReviewController
        .acceptPassenger(passenger.carpoolPassengerId!);

    if (success) {
      // Optionally remove the passenger from the list or refresh the data
      setState(() {
        widget.trip.passengers?.removeWhere(
          (p) => p.carpoolPassengerId == passenger.carpoolPassengerId,
        );
      });
    }
  }

  void _rejectPassenger(Passenger passenger) async {
    if (passenger.carpoolPassengerId == null) {
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'invalid_passenger_data'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));
      return;
    }

    // Show confirmation dialog
    final confirmed = await _showRejectConfirmationDialog(passenger);
    if (!confirmed) return;

    final success = await _passengerReviewController
        .rejectPassenger(passenger.carpoolPassengerId!);

    if (success) {
      // Optionally remove the passenger from the list or refresh the data
      setState(() {
        widget.trip.passengers?.removeWhere(
          (p) => p.carpoolPassengerId == passenger.carpoolPassengerId,
        );
      });
    }
  }

  Future<bool> _showRejectConfirmationDialog(Passenger passenger) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('confirm_rejection'.tr),
            content: Text(
              '${'are_you_sure_reject_passenger'.tr} ${passenger.name ?? 'this_passenger'.tr}?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'cancel'.tr,
                  style: TextStyle(color: Theme.of(context).hintColor),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'reject'.tr,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }
}
