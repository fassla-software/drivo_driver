import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/pusher_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/dashboard/screens/dashboard_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/screens/map_screen.dart';
import 'package:ride_sharing_user_app/features/map/widgets/bid_accepting_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/bidding_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/customer_info_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/route_widget.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/domain/models/trip_details_model.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/trip/screens/payment_received_screen.dart';
import 'package:ride_sharing_user_app/features/trip/screens/review_this_customer_screen.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_dialog_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/button_widget.dart';

class CustomerRideRequestCardWidget extends StatefulWidget {
  final TripDetail rideRequest;
  final bool fromList;
  final String? pickupTime;
  final bool fromParcel;
  final int? index;
  const CustomerRideRequestCardWidget(
      {super.key,
      required this.rideRequest,
      this.fromList = false,
      this.pickupTime,
      this.fromParcel = false,
      this.index});

  @override
  State<CustomerRideRequestCardWidget> createState() =>
      _CustomerRideRequestCardWidgetState();
}

class _CustomerRideRequestCardWidgetState
    extends State<CustomerRideRequestCardWidget> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseAnimationController;
  late AnimationController _glowAnimationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // التحكم الرئيسي في الرسوم المتحركة
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // تحكم نبض البطاقة
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // تحكم توهج البطاقة
    _glowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // الرسوم المتحركة الرئيسية
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutBack,
    ));

    _rotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutBack,
    ));

    // رسوم متحركة النبض
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    // رسوم متحركة التوهج
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowAnimationController,
      curve: Curves.easeInOut,
    ));

    // تشغيل الرسوم المتحركة
    _startAnimations();
  }

  void _startAnimations() async {
    await _mainAnimationController.forward();
    _pulseAnimationController.repeat(reverse: true);
    _glowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _pulseAnimationController.dispose();
    _glowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String firstRoute = '';
    String secondRoute = '';
    List<dynamic> extraRoute = [];
    if (widget.rideRequest.intermediateAddresses != null &&
        widget.rideRequest.intermediateAddresses != '[[, ]]') {
      extraRoute = jsonDecode(widget.rideRequest.intermediateAddresses!);
      if (extraRoute.isNotEmpty) {
        firstRoute = extraRoute[0];
      }
      if (extraRoute.isNotEmpty && extraRoute.length > 1) {
        secondRoute = extraRoute[1];
      }
    }
    bool bidOn = Get.find<SplashController>().config!.bidOnFare!;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainAnimationController,
        _pulseAnimationController,
        _glowAnimationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value * _pulseAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: !widget.fromList
                    ? GetBuilder<RideController>(builder: (rideController) {
                        return InkWell(
                          onTap: () {
                            if (widget.fromParcel) {
                              Get.find<RiderMapController>()
                                  .setRideCurrentState(RideState.ongoing);
                              Get.find<RideController>()
                                  .getRideDetails(widget.rideRequest.id!)
                                  .then((value) {
                                if (value.statusCode == 200) {
                                  Get.find<RideController>()
                                      .updateRoute(false, notify: true);
                                  Get.to(() =>
                                      const MapScreen(fromScreen: 'splash'));
                                }
                              });
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: Dimensions.paddingSizeDefault,
                              vertical: Dimensions.paddingSizeExtraSmall,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(
                                  Dimensions.paddingSizeDefault),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white,
                                    Colors.white.withValues(alpha: 0.98),
                                    Colors.white.withValues(alpha: 0.95),
                                    Colors.white.withValues(alpha: 0.92),
                                  ],
                                  stops: const [0.0, 0.3, 0.7, 1.0],
                                ),
                                borderRadius: BorderRadius.circular(
                                    Dimensions.paddingSizeDefault + 5),
                                border: Border.all(
                                  color: Theme.of(Get.context!)
                                      .primaryColor
                                      .withValues(alpha: 0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(Get.context!)
                                        .primaryColor
                                        .withValues(
                                            alpha: 0.2 * _glowAnimation.value),
                                    blurRadius: 30,
                                    offset: const Offset(0, 15),
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                  BoxShadow(
                                    color: Theme.of(Get.context!)
                                        .primaryColor
                                        .withValues(
                                            alpha: 0.1 * _glowAnimation.value),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(children: [
                                if (!widget.fromParcel)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: Dimensions.paddingSizeSmall,
                                      vertical:
                                          Dimensions.paddingSizeExtraSmall,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.15),
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.05),
                                        ],
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Theme.of(context).primaryColor,
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.8),
                                              ],
                                            ),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            Icons.swipe_left,
                                            size: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'swipe_to_reject'.tr,
                                          style: textRegular.copyWith(
                                            color:
                                                Theme.of(context).primaryColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeDefault,
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1),
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.05),
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.category,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'trip_type'.tr,
                                              style: textRegular.copyWith(
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(
                                          width:
                                              Dimensions.paddingSizeExtraSmall),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeSmall,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context).primaryColor,
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.8),
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.7),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                              Dimensions.paddingSizeDefault),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 15,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          widget.rideRequest.type!.tr,
                                          style: textRegular.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: Dimensions.fontSizeLarge,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                RouteWidget(
                                  fromCard: true,
                                  pickupAddress:
                                      widget.rideRequest.pickupAddress!,
                                  destinationAddress:
                                      widget.rideRequest.destinationAddress!,
                                  extraOne: firstRoute,
                                  extraTwo: secondRoute,
                                  entrance: widget.rideRequest.entrance ?? '',
                                ),
                                if (widget.rideRequest.customer != null)
                                  CustomerInfoWidget(
                                    fromTripDetails: false,
                                    customer: widget.rideRequest.customer!,
                                    fare: widget.rideRequest.estimatedFare!,
                                    customerRating:
                                        widget.rideRequest.customerAvgRating!,
                                  ),
                                Get.find<RideController>().matchedMode != null
                                    ? Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal:
                                              Dimensions.paddingSizeDefault,
                                          vertical: Dimensions.paddingSizeSmall,
                                        ),
                                        padding: const EdgeInsets.all(
                                            Dimensions.paddingSizeDefault),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.15),
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.1),
                                              Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.05),
                                            ],
                                            stops: const [0.0, 0.5, 1.0],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.3),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Theme.of(context)
                                                      .primaryColor,
                                                  Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.8),
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Icon(
                                              Icons.access_time,
                                              size: 20,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${Get.find<RideController>().matchedMode!.duration!} ${'pickup_time'.tr}',
                                            style: textRegular.copyWith(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.w700,
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                            ),
                                          ),
                                        ]),
                                      )
                                    : const SizedBox(),
                                widget.fromParcel
                                    ? Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          Dimensions.paddingSizeDefault,
                                          Dimensions.paddingSizeSmall,
                                          Dimensions.paddingSizeDefault,
                                          Dimensions.paddingSizeDefault,
                                        ),
                                        child: SizedBox(
                                          width: 250,
                                          child: Row(children: [
                                            Expanded(
                                              child: Container(
                                                height: 50,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Theme.of(context)
                                                          .primaryColor,
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                              alpha: 0.8),
                                                      Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                              alpha: 0.7),
                                                    ],
                                                    stops: const [
                                                      0.0,
                                                      0.5,
                                                      1.0
                                                    ],
                                                  ),
                                                  borderRadius: BorderRadius
                                                      .circular(Dimensions
                                                          .paddingSizeDefault),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                              alpha: 0.4),
                                                      blurRadius: 20,
                                                      offset:
                                                          const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Material(
                                                  color: Colors.transparent,
                                                  child: InkWell(
                                                    borderRadius: BorderRadius
                                                        .circular(Dimensions
                                                            .paddingSizeDefault),
                                                    onTap: () async {
                                                      if (widget.rideRequest
                                                              .paymentStatus ==
                                                          'paid') {
                                                        Get.dialog(
                                                          barrierDismissible:
                                                              false,
                                                          ConfirmationDialogWidget(
                                                            icon: Images.logo,
                                                            description:
                                                                'are_you_sure'
                                                                    .tr,
                                                            onYesPressed: () {
                                                              if (Get.find<RideController>()
                                                                          .matchedMode !=
                                                                      null &&
                                                                  (Get.find<RideController>()
                                                                              .matchedMode!
                                                                              .distance! *
                                                                          1000) <=
                                                                      Get.find<
                                                                              SplashController>()
                                                                          .config!
                                                                          .completionRadius!) {
                                                                Get.find<
                                                                        RideController>()
                                                                    .tripStatusUpdate(
                                                                  'completed',
                                                                  widget
                                                                      .rideRequest
                                                                      .id!,
                                                                  "trip_completed_successfully",
                                                                  '',
                                                                )
                                                                    .then(
                                                                        (value) async {
                                                                  if (value
                                                                          .statusCode ==
                                                                      200) {
                                                                    if (Get.find<
                                                                            SplashController>()
                                                                        .config!
                                                                        .reviewStatus!) {
                                                                      Get.offAll(() => ReviewThisCustomerScreen(
                                                                          tripId: widget
                                                                              .rideRequest
                                                                              .id!));
                                                                    } else {
                                                                      Get.find<
                                                                              RiderMapController>()
                                                                          .setRideCurrentState(
                                                                              RideState.initial);
                                                                      Get.off(() =>
                                                                          const DashboardScreen());
                                                                    }
                                                                  }
                                                                });
                                                              } else {
                                                                Get.back();
                                                                showCustomSnackBar(
                                                                  "you_are_not_reached_destination"
                                                                      .tr,
                                                                );
                                                              }
                                                            },
                                                          ),
                                                        );
                                                      } else {
                                                        if (widget
                                                                .rideRequest
                                                                .parcelInformation!
                                                                .payer ==
                                                            'sender') {
                                                          rideController
                                                              .tripStatusUpdate(
                                                            'completed',
                                                            widget.rideRequest
                                                                .id!,
                                                            "trip_completed_successfully",
                                                            '',
                                                          )
                                                              .then(
                                                                  (value) async {
                                                            rideController
                                                                .getFinalFare(widget
                                                                    .rideRequest
                                                                    .id!)
                                                                .then((value) {
                                                              if (value
                                                                      .statusCode ==
                                                                  200) {
                                                                if (Get.find<
                                                                        SplashController>()
                                                                    .config!
                                                                    .reviewStatus!) {
                                                                  Get.offAll(() =>
                                                                      ReviewThisCustomerScreen(
                                                                        tripId: rideController
                                                                            .tripDetail!
                                                                            .id!,
                                                                      ));
                                                                } else {
                                                                  Get.offAll(() =>
                                                                      const DashboardScreen());
                                                                }
                                                              }
                                                            });
                                                          });
                                                        } else {
                                                          if (Get.find<RideController>()
                                                                      .matchedMode !=
                                                                  null &&
                                                              (Get.find<RideController>()
                                                                          .matchedMode!
                                                                          .distance! *
                                                                      1000) <=
                                                                  Get.find<
                                                                          SplashController>()
                                                                      .config!
                                                                      .completionRadius!) {
                                                            rideController
                                                                .tripStatusUpdate(
                                                              'completed',
                                                              widget.rideRequest
                                                                  .id!,
                                                              "trip_completed_successfully",
                                                              '',
                                                            )
                                                                .then(
                                                                    (value) async {
                                                              if (value
                                                                      .statusCode ==
                                                                  200) {
                                                                Get.find<
                                                                        RideController>()
                                                                    .getFinalFare(
                                                                        widget
                                                                            .rideRequest
                                                                            .id!)
                                                                    .then(
                                                                        (value) {
                                                                  if (value
                                                                          .statusCode ==
                                                                      200) {
                                                                    Get.find<
                                                                            RiderMapController>()
                                                                        .setRideCurrentState(
                                                                            RideState.initial);
                                                                    Get.to(() =>
                                                                        const PaymentReceivedScreen());
                                                                  }
                                                                });
                                                              }
                                                            });
                                                          } else {
                                                            showCustomSnackBar(
                                                                "you_are_not_reached_destination"
                                                                    .tr);
                                                          }
                                                        }
                                                      }
                                                    },
                                                    child: Center(
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(6),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: Colors
                                                                  .white
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                              shape: BoxShape
                                                                  .circle,
                                                            ),
                                                            child: Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            'complete'.tr,
                                                            style: textBold
                                                                .copyWith(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: Dimensions
                                                                  .fontSizeLarge,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                        ),
                                      )
                                    : GetBuilder<RideController>(
                                        builder: (rideController) {
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeDefault,
                                            vertical:
                                                Dimensions.paddingSizeDefault,
                                          ),
                                          child: rideController.accepting
                                              ? Container(
                                                  padding: const EdgeInsets.all(
                                                      Dimensions
                                                          .paddingSizeDefault),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      begin: Alignment.topLeft,
                                                      end:
                                                          Alignment.bottomRight,
                                                      colors: [
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.15),
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.1),
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.05),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            25),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .primaryColor
                                                          .withValues(
                                                              alpha: 0.3),
                                                      width: 1.5,
                                                    ),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.2),
                                                        blurRadius: 15,
                                                        offset:
                                                            const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child: SpinKitCircle(
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    size: 40.0,
                                                  ),
                                                )
                                              : Row(children: [
                                                  Expanded(
                                                    child: Container(
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Colors.white,
                                                            Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.98),
                                                            Colors.white
                                                                .withValues(
                                                                    alpha:
                                                                        0.95),
                                                          ],
                                                          stops: const [
                                                            0.0,
                                                            0.5,
                                                            1.0
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius
                                                            .circular(Dimensions
                                                                .paddingSizeDefault),
                                                        border: Border.all(
                                                          color: Theme.of(
                                                                  Get.context!)
                                                              .primaryColorDark,
                                                          width: 2.5,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha:
                                                                        0.15),
                                                            blurRadius: 15,
                                                            offset:
                                                                const Offset(
                                                                    0, 6),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .paddingSizeDefault),
                                                          onTap: () {
                                                            if (bidOn &&
                                                                widget.rideRequest
                                                                        .fareBiddings !=
                                                                    null &&
                                                                widget
                                                                    .rideRequest
                                                                    .fareBiddings!
                                                                    .isEmpty &&
                                                                widget.rideRequest
                                                                        .type !=
                                                                    'parcel') {
                                                              showDialog(
                                                                context: Get
                                                                    .context!,
                                                                builder: (_) =>
                                                                    BiddingDialogWidget(
                                                                        rideRequest:
                                                                            widget.rideRequest),
                                                              );
                                                            } else {
                                                              rideController
                                                                  .tripAcceptOrRejected(
                                                                      widget
                                                                          .rideRequest
                                                                          .id!,
                                                                      'rejected')
                                                                  .then(
                                                                      (value) async {
                                                                if (value
                                                                        .statusCode ==
                                                                    200) {
                                                                  Get.offAll(() =>
                                                                      const DashboardScreen());
                                                                  Get.find<
                                                                          RiderMapController>()
                                                                      .setRideCurrentState(
                                                                          RideState
                                                                              .initial);
                                                                }
                                                              });
                                                            }
                                                          },
                                                          child: Center(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          6),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Theme.of(Get
                                                                            .context!)
                                                                        .primaryColorDark
                                                                        .withValues(
                                                                            alpha:
                                                                                0.1),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: Icon(
                                                                    Icons.close,
                                                                    color: Theme.of(
                                                                            Get.context!)
                                                                        .primaryColorDark,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Text(
                                                                  (bidOn &&
                                                                          widget.rideRequest.type !=
                                                                              'parcel' &&
                                                                          widget.rideRequest.fareBiddings !=
                                                                              null &&
                                                                          widget
                                                                              .rideRequest
                                                                              .fareBiddings!
                                                                              .isEmpty)
                                                                      ? 'bid'.tr
                                                                      : 'reject'
                                                                          .tr,
                                                                  style: textBold
                                                                      .copyWith(
                                                                    color: Theme.of(
                                                                            Get.context!)
                                                                        .primaryColorDark,
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: Dimensions
                                                          .paddingSizeLarge),
                                                  Expanded(
                                                    child: Container(
                                                      height: 50,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Theme.of(context)
                                                                .primaryColor,
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.8),
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.7),
                                                          ],
                                                          stops: const [
                                                            0.0,
                                                            0.5,
                                                            1.0
                                                          ],
                                                        ),
                                                        borderRadius: BorderRadius
                                                            .circular(Dimensions
                                                                .paddingSizeDefault),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.5),
                                                            blurRadius: 20,
                                                            offset:
                                                                const Offset(
                                                                    0, 8),
                                                          ),
                                                        ],
                                                      ),
                                                      child: Material(
                                                        color:
                                                            Colors.transparent,
                                                        child: InkWell(
                                                          borderRadius: BorderRadius
                                                              .circular(Dimensions
                                                                  .paddingSizeDefault),
                                                          onTap: () async {
                                                            rideController
                                                                .tripAcceptOrRejected(
                                                              widget.rideRequest
                                                                  .id!,
                                                              'accepted',
                                                              fromList: true,
                                                              index: widget
                                                                      .index ??
                                                                  0,
                                                            )
                                                                .then(
                                                                    (value) async {
                                                              if (value
                                                                      .statusCode ==
                                                                  200) {
                                                                Get.find<
                                                                        AuthController>()
                                                                    .saveRideCreatedTime();
                                                                Get.find<
                                                                        RiderMapController>()
                                                                    .setRideCurrentState(
                                                                        RideState
                                                                            .accepted);
                                                                Get.find<
                                                                        RideController>()
                                                                    .updateRoute(
                                                                        false,
                                                                        notify:
                                                                            true);
                                                                Get.find<
                                                                        RideController>()
                                                                    .remainingDistance(
                                                                        widget
                                                                            .rideRequest
                                                                            .id!,
                                                                        mapBound:
                                                                            true);
                                                                Get.to(() =>
                                                                    const MapScreen());
                                                                PusherHelper()
                                                                    .customerCouponAppliedOrRemoved(widget
                                                                        .rideRequest
                                                                        .id!);
                                                              }
                                                            });
                                                          },
                                                          child: Center(
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .center,
                                                              children: [
                                                                Container(
                                                                  padding:
                                                                      const EdgeInsets
                                                                          .all(
                                                                          6),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white
                                                                        .withValues(
                                                                            alpha:
                                                                                0.2),
                                                                    shape: BoxShape
                                                                        .circle,
                                                                  ),
                                                                  child: Icon(
                                                                    Icons
                                                                        .check_circle,
                                                                    color: Colors
                                                                        .white,
                                                                    size: 20,
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                    width: 8),
                                                                Text(
                                                                  'accept'.tr,
                                                                  style: textBold
                                                                      .copyWith(
                                                                    color: Colors
                                                                        .white,
                                                                    fontSize:
                                                                        Dimensions
                                                                            .fontSizeLarge,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ]),
                                        );
                                      }),
                              ]),
                            ),
                          ),
                        );
                      })
                    : Slidable(
                        key: const ValueKey(0),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          dragDismissible: false,
                          children: [
                            SlidableAction(
                              onPressed: (value) {
                                Get.find<RideController>()
                                    .tripAcceptOrRejected(
                                        widget.rideRequest.id!, 'rejected')
                                    .then((value) {
                                  if (value.statusCode == 200) {
                                    Get.find<RideController>()
                                        .getPendingRideRequestList(1);
                                    if (widget.fromList) {
                                      Get.find<RiderMapController>()
                                          .setRideCurrentState(
                                              RideState.initial);
                                    }
                                  }
                                });
                              },
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(.5),
                              foregroundColor:
                                  Theme.of(context).colorScheme.error,
                              icon: Icons.delete_forever_rounded,
                              label: 'reject'.tr,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Dimensions.paddingSizeDefault,
                            vertical: Dimensions.paddingSizeExtraSmall,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeLarge),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Colors.white.withValues(alpha: 0.98),
                                  Colors.white.withValues(alpha: 0.95),
                                  Colors.white.withValues(alpha: 0.92),
                                ],
                                stops: const [0.0, 0.3, 0.7, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(
                                  Dimensions.paddingSizeLarge + 10),
                              border: Border.all(
                                color: Theme.of(Get.context!)
                                    .primaryColor
                                    .withValues(alpha: 0.2),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(Get.context!)
                                      .primaryColor
                                      .withValues(
                                          alpha: 0.2 * _glowAnimation.value),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: Theme.of(Get.context!)
                                      .primaryColor
                                      .withValues(
                                          alpha: 0.1 * _glowAnimation.value),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                  vertical: Dimensions.paddingSizeSmall,
                                ),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.15),
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.1),
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.05),
                                    ],
                                    stops: const [0.0, 0.5, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .primaryColor
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.2),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.8),
                                          ],
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        Icons.swipe_left,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'swipe_to_reject'.tr,
                                      style: textRegular.copyWith(
                                        color: Theme.of(context).primaryColor,
                                        fontWeight: FontWeight.w700,
                                        fontSize: Dimensions.fontSizeDefault,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: Dimensions.paddingSizeDefault),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.1),
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.05),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.category,
                                            size: 20,
                                            color:
                                                Theme.of(context).primaryColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'trip_type'.tr,
                                            style: textRegular.copyWith(
                                              fontSize:
                                                  Dimensions.fontSizeLarge,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(
                                        width:
                                            Dimensions.paddingSizeExtraSmall),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal:
                                            Dimensions.paddingSizeDefault,
                                        vertical: Dimensions.paddingSizeSmall,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: [
                                            Theme.of(context).primaryColor,
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.8),
                                            Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.7),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                            Dimensions.paddingSizeDefault),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Theme.of(context)
                                                .primaryColor
                                                .withValues(alpha: 0.4),
                                            blurRadius: 15,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        widget.rideRequest.type!.tr,
                                        style: textRegular.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: Dimensions.fontSizeLarge,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RouteWidget(
                                fromCard: true,
                                pickupAddress:
                                    widget.rideRequest.pickupAddress!,
                                destinationAddress:
                                    widget.rideRequest.destinationAddress!,
                                extraOne: firstRoute,
                                extraTwo: secondRoute,
                                entrance: widget.rideRequest.entrance ?? '',
                              ),
                              if (widget.rideRequest.customer != null)
                                CustomerInfoWidget(
                                  fromTripDetails: false,
                                  customer: widget.rideRequest.customer!,
                                  fare: widget.rideRequest.estimatedFare!,
                                  customerRating:
                                      widget.rideRequest.customerAvgRating!,
                                ),
                              GetBuilder<RideController>(
                                  builder: (rideController) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: Dimensions.paddingSizeDefault,
                                    vertical: Dimensions.paddingSizeDefault,
                                  ),
                                  child: rideController.pendingRideRequestModel!
                                                  .data![widget.index!].id ==
                                              rideController.onPressedTripId &&
                                          rideController.accepting
                                      ? Container(
                                          padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeDefault),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.15),
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.05),
                                              ],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.3),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.2),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: SpinKitCircle(
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 40.0,
                                          ),
                                        )
                                      : Row(children: [
                                          Expanded(
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Colors.white,
                                                    Colors.white.withValues(
                                                        alpha: 0.98),
                                                    Colors.white.withValues(
                                                        alpha: 0.95),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                                borderRadius: BorderRadius
                                                    .circular(Dimensions
                                                        .paddingSizeDefault),
                                                border: Border.all(
                                                  color: Theme.of(Get.context!)
                                                      .primaryColor,
                                                  width: 2.5,
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.15),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 6),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius
                                                      .circular(Dimensions
                                                          .paddingSizeDefault),
                                                  onTap: () {
                                                    if (bidOn &&
                                                        widget.rideRequest
                                                                .fareBiddings !=
                                                            null &&
                                                        widget
                                                            .rideRequest
                                                            .fareBiddings!
                                                            .isEmpty &&
                                                        widget.rideRequest
                                                                .type !=
                                                            'parcel') {
                                                      showDialog(
                                                        context: Get.context!,
                                                        builder: (_) =>
                                                            BiddingDialogWidget(
                                                                rideRequest: widget
                                                                    .rideRequest),
                                                      );
                                                    } else {
                                                      Get.find<RideController>()
                                                          .tripAcceptOrRejected(
                                                              widget.rideRequest
                                                                  .id!,
                                                              'rejected',
                                                              index: widget
                                                                      .index ??
                                                                  0)
                                                          .then((value) {
                                                        if (value.statusCode ==
                                                            200) {
                                                          Get.find<
                                                                  RideController>()
                                                              .getPendingRideRequestList(
                                                                  1);
                                                          if (widget.fromList) {
                                                            Get.find<
                                                                    RiderMapController>()
                                                                .setRideCurrentState(
                                                                    RideState
                                                                        .initial);
                                                          }
                                                        }
                                                      });
                                                    }
                                                  },
                                                  child: Center(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Theme.of(Get
                                                                    .context!)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.close,
                                                            color: Theme.of(Get
                                                                    .context!)
                                                                .primaryColor,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          (bidOn &&
                                                                  widget.rideRequest
                                                                          .type !=
                                                                      'parcel' &&
                                                                  widget.rideRequest
                                                                          .fareBiddings !=
                                                                      null &&
                                                                  widget
                                                                      .rideRequest
                                                                      .fareBiddings!
                                                                      .isEmpty)
                                                              ? 'bid'.tr
                                                              : 'reject'.tr,
                                                          style:
                                                              textBold.copyWith(
                                                            color: Theme.of(Get
                                                                    .context!)
                                                                .primaryColor,
                                                            fontSize: Dimensions
                                                                .fontSizeLarge,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(
                                              width:
                                                  Dimensions.paddingSizeLarge),
                                          Expanded(
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Theme.of(context)
                                                        .primaryColor,
                                                    Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.8),
                                                    Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.7),
                                                  ],
                                                  stops: const [0.0, 0.5, 1.0],
                                                ),
                                                borderRadius: BorderRadius
                                                    .circular(Dimensions
                                                        .paddingSizeDefault),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Theme.of(context)
                                                        .primaryColor
                                                        .withValues(alpha: 0.5),
                                                    blurRadius: 20,
                                                    offset: const Offset(0, 8),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius: BorderRadius
                                                      .circular(Dimensions
                                                          .paddingSizeDefault),
                                                  onTap: () async {
                                                    Get.find<RideController>()
                                                        .tripAcceptOrRejected(
                                                            widget.rideRequest
                                                                .id!,
                                                            'accepted',
                                                            index:
                                                                widget.index ??
                                                                    0)
                                                        .then((value) async {
                                                      if (value.statusCode ==
                                                          200) {
                                                        Get.find<
                                                                AuthController>()
                                                            .saveRideCreatedTime();
                                                        if (widget.fromList) {
                                                          Get.find<
                                                                  RideController>()
                                                              .getRideDetails(
                                                                  widget
                                                                      .rideRequest
                                                                      .id!)
                                                              .then(
                                                                  (value) async {
                                                            if (value
                                                                    .statusCode ==
                                                                200) {
                                                              Get.find<
                                                                      RiderMapController>()
                                                                  .setRideCurrentState(
                                                                      RideState
                                                                          .accepted);
                                                              Get.find<
                                                                      RideController>()
                                                                  .updateRoute(
                                                                      false,
                                                                      notify:
                                                                          true);
                                                              Get.to(() =>
                                                                  const MapScreen());
                                                            }
                                                          });
                                                        } else {
                                                          Get.dialog(
                                                              const BidAcceptingDialogueWidget(),
                                                              barrierDismissible:
                                                                  false);
                                                          await Future.delayed(
                                                              const Duration(
                                                                  seconds: 5));
                                                          Get.back();
                                                          Get.find<
                                                                  RiderMapController>()
                                                              .setRideCurrentState(
                                                                  RideState
                                                                      .accepted);
                                                          Get.to(() =>
                                                              const MapScreen());
                                                        }
                                                      }
                                                    });
                                                  },
                                                  child: Center(
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(6),
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.white
                                                                .withValues(
                                                                    alpha: 0.2),
                                                            shape:
                                                                BoxShape.circle,
                                                          ),
                                                          child: Icon(
                                                            Icons.check_circle,
                                                            color: Colors.white,
                                                            size: 20,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          'accept'.tr,
                                                          style:
                                                              textBold.copyWith(
                                                            color: Colors.white,
                                                            fontSize: Dimensions
                                                                .fontSizeLarge,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ]),
                                );
                              }),
                            ]),
                          ),
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
