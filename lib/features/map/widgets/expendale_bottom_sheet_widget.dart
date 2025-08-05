import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/expandable_bottom_sheet.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:ride_sharing_user_app/features/map/controllers/map_controller.dart';
import 'package:ride_sharing_user_app/features/map/widgets/calculating_sub_total_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/accepted_rider_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/custom_icon_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/customer_ride_request_card_widget.dart';
import 'package:ride_sharing_user_app/features/map/widgets/end_trip_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/ride/screens/ride_request_list_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'stay_online_widget.dart';
import 'ride_ongoing_widget.dart';

class RiderBottomSheetWidget extends StatefulWidget {
  final GlobalKey<ExpandableBottomSheetState> expandableKey;
  const RiderBottomSheetWidget({super.key, required this.expandableKey});

  @override
  State<RiderBottomSheetWidget> createState() => _RiderBottomSheetWidgetState();
}

class _RiderBottomSheetWidgetState extends State<RiderBottomSheetWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _handleAnimationController;
  late AnimationController _contentAnimationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _handleScaleAnimation;
  late Animation<double> _handleRotationAnimation;
  late Animation<double> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    super.initState();

    // التحكم الرئيسي في الرسوم المتحركة
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // تحكم مقبض البوتوم شيت
    _handleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // تحكم محتوى البوتوم شيت
    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // الرسوم المتحركة الرئيسية
    _scaleAnimation = Tween<double>(
      begin: 0.9,
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
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainAnimationController,
      curve: Curves.easeOutBack,
    ));

    // رسوم متحركة للمقبض
    _handleScaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _handleAnimationController,
      curve: Curves.bounceOut,
    ));

    _handleRotationAnimation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _handleAnimationController,
      curve: Curves.easeOutBack,
    ));

    // رسوم متحركة للمحتوى
    _contentSlideAnimation = Tween<double>(
      begin: 20.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

    // تشغيل الرسوم المتحركة بالتسلسل
    _startAnimations();
  }

  void _startAnimations() async {
    await _mainAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _handleAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _handleAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _mainAnimationController,
        _handleAnimationController,
        _contentAnimationController,
      ]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.translate(
              offset: Offset(0, _slideAnimation.value),
              child: GetBuilder<RiderMapController>(builder: (riderController) {
                return GetBuilder<RideController>(builder: (rideController) {
                  return GetBuilder<ProfileController>(
                      builder: (profileController) {
                    return Column(children: [
                      Container(
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
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(
                                Dimensions.paddingSizeLarge + 5),
                            topRight: Radius.circular(
                                Dimensions.paddingSizeLarge + 5),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.2),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                          border: Border.all(
                            color: Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.15),
                            width: 2,
                          ),
                        ),
                        width: MediaQuery.of(context).size.width,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: Dimensions.paddingSizeDefault,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // مقبض البوتوم شيت المحسن مع الرسوم المتحركة
                              Transform.scale(
                                scale: _handleScaleAnimation.value,
                                child: Transform.rotate(
                                  angle: _handleRotationAnimation.value,
                                  child: Container(
                                    height: 8,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.4),
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.3),
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.2),
                                          Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.1),
                                        ],
                                        stops: const [0.0, 0.3, 0.7, 1.0],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        Dimensions.paddingSizeExtraSmall + 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.3),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withValues(alpha: 0.2),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: Dimensions.paddingSizeDefault),

                              // محتوى البوتوم شيت مع الرسوم المتحركة
                              Transform.translate(
                                offset: Offset(0, _contentSlideAnimation.value),
                                child: Opacity(
                                  opacity: _contentFadeAnimation.value,
                                  child: Column(
                                    children: [
                                      if (riderController.currentRideState ==
                                          RideState.initial)
                                        const StayOnlineWidget(),
                                      if (riderController.currentRideState ==
                                          RideState.pending)
                                        GetBuilder<RideController>(
                                            builder: (rideController) {
                                          return CustomerRideRequestCardWidget(
                                            rideRequest:
                                                rideController.tripDetail!,
                                          );
                                        }),
                                      if (riderController.currentRideState ==
                                          RideState.accepted)
                                        RideAcceptedWidget(
                                            expandableKey:
                                                widget.expandableKey),
                                      if (riderController.currentRideState ==
                                          RideState.ongoing)
                                        RideOngoingWidget(
                                          tripId:
                                              rideController.tripDetail?.id ??
                                                  '',
                                          expandableKey: widget.expandableKey,
                                        ),
                                      if (riderController.currentRideState ==
                                          RideState.end)
                                        const EndTripWidget(),
                                      if (riderController.currentRideState ==
                                          RideState.completed)
                                        const CalculatingSubTotalWidget(),

                                      // أزرار التحكم المحسنة مع تصميم فريد
                                      if (riderController.currentRideState ==
                                          RideState.initial)
                                        Container(
                                          margin: const EdgeInsets.symmetric(
                                            horizontal:
                                                Dimensions.paddingSizeDefault,
                                          ),
                                          padding: const EdgeInsets.all(
                                              Dimensions.paddingSizeLarge),
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.08),
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.05),
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.03),
                                                Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.01),
                                              ],
                                              stops: const [0.0, 0.3, 0.7, 1.0],
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(25),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .primaryColor
                                                  .withValues(alpha: 0.15),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.1),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                              BoxShadow(
                                                color: Colors.black
                                                    .withValues(alpha: 0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              rideController.isLoading
                                                  ? Container(
                                                      padding: const EdgeInsets
                                                          .all(Dimensions
                                                              .paddingSizeDefault),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          begin:
                                                              Alignment.topLeft,
                                                          end: Alignment
                                                              .bottomRight,
                                                          colors: [
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.15),
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.08),
                                                            Theme.of(context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha:
                                                                        0.05),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(18),
                                                        border: Border.all(
                                                          color:
                                                              Theme.of(context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                          width: 1,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            blurRadius: 10,
                                                            offset:
                                                                const Offset(
                                                                    0, 3),
                                                          ),
                                                        ],
                                                      ),
                                                      child:
                                                          const LoaderWidget(),
                                                    )
                                                  : CustomIconCardWidget(
                                                      title: 'refresh'.tr,
                                                      index: 0,
                                                      icon: Images.mIcon3,
                                                      iconColor:
                                                          Theme.of(context)
                                                              .primaryColor,
                                                      onTap: () {
                                                        rideController
                                                            .getPendingRideRequestList(
                                                                1,
                                                                isUpdate: true);
                                                      },
                                                    ),
                                              CustomIconCardWidget(
                                                title: 'leader_board'.tr,
                                                iconColor: Theme.of(context)
                                                    .primaryColor,
                                                index: 1,
                                                icon: Images.mIcon2,
                                                onTap: () => Get.to(() =>
                                                    const LeaderboardScreen()),
                                              ),
                                              CustomIconCardWidget(
                                                title: 'trip_request'.tr,
                                                iconColor: Theme.of(context)
                                                    .primaryColor,
                                                index: 2,
                                                icon: Images.mIcon1,
                                                onTap: () => Get.to(() =>
                                                    const RideRequestScreen()),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              const SizedBox(
                                  height: Dimensions.paddingSizeDefault),
                            ],
                          ),
                        ),
                      ),
                    ]);
                  });
                });
              }),
            ),
          ),
        );
      },
    );
  }
}
