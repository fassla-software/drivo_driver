import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/app_bar_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/sliver_delegate.dart';
import 'package:ride_sharing_user_app/common_widgets/zoom_drawer_context_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/add_vehicle_design_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/custom_menu/custom_menu_button_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/custom_menu/custom_menu_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_bottom_sheet_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/home_referral_view_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/my_activity_list_view_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/ongoing_ride_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/profile_info_card_widget.dart';
import 'package:ride_sharing_user_app/features/home/widgets/refund_alert_bottomsheet.dart';
import 'package:ride_sharing_user_app/features/home/widgets/vehicle_pending_widget.dart';
import 'package:ride_sharing_user_app/features/notification/widgets/notification_shimmer_widget.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/controllers/out_of_zone_controller.dart';
import 'package:ride_sharing_user_app/features/out_of_zone/screens/out_of_zone_map_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_menu_screen.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/home_screen_helper.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class HomeMenu extends GetView<ProfileController> {
  const HomeMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ProfileController>(
      builder: (_) => ZoomDrawer(
        controller: _.zoomDrawerController,
        menuScreen: const ProfileMenuScreen(),
        mainScreen: const HomeScreen(),
        borderRadius: 24.0,
        isRtl: !Get.find<LocalizationController>().isLtr,
        angle: -5.0,
        menuBackgroundColor: Theme.of(context).primaryColor,
        slideWidth: MediaQuery.of(context).size.width * 0.85,
        mainScreenScale: .4,
        mainScreenTapClose: true,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _profileCardAnimationController;
  late AnimationController _contentAnimationController;
  late AnimationController _fabAnimationController;

  late Animation<double> _headerSlideAnimation;
  late Animation<double> _headerFadeAnimation;
  late Animation<double> _profileCardSlideAnimation;
  late Animation<double> _profileCardFadeAnimation;
  late Animation<double> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabFadeAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة الرسوم المتحركة
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _profileCardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // رأس متحرك
    _headerSlideAnimation = Tween<double>(
      begin: -50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _headerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeInOut,
    ));

    // بطاقة الملف الشخصي متحركة
    _profileCardSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _profileCardAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _profileCardFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _profileCardAnimationController,
      curve: Curves.easeInOut,
    ));

    // محتوى متحرك
    _contentSlideAnimation = Tween<double>(
      begin: 100.0,
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

    // زر متحرك
    _fabScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _fabFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    // بدء الرسوم المتحركة
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 200), () {
      _profileCardAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 400), () {
      _contentAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _fabAnimationController.forward();
    });

    WidgetsFlutterBinding.ensureInitialized();
    loadData();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _profileCardAnimationController.dispose();
    _contentAnimationController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    Get.find<ProfileController>().getCategoryList(1);
    Get.find<ProfileController>().getProfileInfo();
    Get.find<ProfileController>().getDailyLog();

    loadOngoingList();

    Get.find<ProfileController>().getProfileLevelInfo();
    if (Get.find<RideController>().ongoingTripDetails != null) {
      HomeScreenHelper().pendingLastRidePusherImplementation();
    }

    await Get.find<RideController>().getPendingRideRequestList(1, limit: 100);
    if (Get.find<RideController>().getPendingRideRequestModel != null) {
      HomeScreenHelper().pendingParcelListPusherImplementation();
    }
    if (Get.find<ProfileController>().profileInfo?.vehicle == null &&
        Get.find<ProfileController>().profileInfo?.vehicleStatus == 0 &&
        Get.find<ProfileController>().isFirstTimeShowBottomSheet) {
      Get.find<ProfileController>().updateFirstTimeShowBottomSheet(false);
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        context: Get.context!,
        isDismissible: false,
        builder: (_) => const HomeBottomSheetWidget(),
      );
    }

    HomeScreenHelper().checkMaintanenceMode();
  }

  Future loadOngoingList() async {
    final RideController rideController = Get.find<RideController>();
    final SplashController splashController = Get.find<SplashController>();

    await rideController.getOngoingParcelList();
    await rideController.getLastTrip();
    Map<String, dynamic>? lastRefundData = splashController.getLastRefundData();

    bool isShowBottomSheet = (rideController.getOnGoingRideCount() == 0) &&
        ((rideController.parcelListModel?.totalSize ?? 0) == 0) &&
        lastRefundData != null;

    if (isShowBottomSheet) {
      await showModalBottomSheet(
          context: Get.context!,
          builder: (ctx) => RefundAlertBottomSheet(
                title: lastRefundData['title'],
                description: lastRefundData['body'],
                tripId: lastRefundData['ride_request_id'],
              ));

      /// Removes the last refund data by setting it to null.
      splashController.addLastReFoundData(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        Get.find<ProfileController>().getProfileInfo();
String? fcmToken = await FirebaseMessaging.instance.getToken();
print('FCM Token: $fcmToken');
      },
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.1),
                Theme.of(context).primaryColor.withValues(alpha: 0.05),
                Colors.white,
              ],
            ),
          ),
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // رأس متحرك
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: SliverDelegate(
                      height: GetPlatform.isIOS ? 150 : 120,
                      child: AnimatedBuilder(
                        animation: _headerAnimationController,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_headerSlideAnimation.value, 0),
                            child: Opacity(
                              opacity: _headerFadeAnimation.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.9),
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.7),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 20,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    AppBarWidget(
                                      title: 'dashboard'.tr,
                                      showBackButton: false,
                                      onTap: () {
                                        Get.find<ProfileController>()
                                            .toggleDrawer();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // محتوى متحرك
                  SliverToBoxAdapter(
                    child: AnimatedBuilder(
                      animation: _contentAnimationController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _contentSlideAnimation.value),
                          child: Opacity(
                            opacity: _contentFadeAnimation.value,
                            child: GetBuilder<ProfileController>(
                              builder: (profileController) {
                                return !profileController.isLoading
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 80.0),

                                          // بطاقة الحالة
                                          if (profileController
                                                      .profileInfo?.vehicle !=
                                                  null &&
                                              profileController.profileInfo
                                                      ?.vehicleStatus !=
                                                  0 &&
                                              profileController.profileInfo
                                                      ?.vehicleStatus !=
                                                  1)
                                            GetBuilder<RideController>(
                                              builder: (rideController) {
                                                return Container(
                                                  margin: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: Dimensions
                                                        .paddingSizeDefault,
                                                    vertical: Dimensions
                                                        .paddingSizeSmall,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withValues(
                                                                alpha: 0.1),
                                                        blurRadius: 15,
                                                        offset:
                                                            const Offset(0, 5),
                                                      ),
                                                    ],
                                                  ),
                                                  child:
                                                      const OngoingRideCardWidget(),
                                                );
                                              },
                                            ),
                                          // إضافة مركبة
                                          if (profileController
                                                      .profileInfo?.vehicle ==
                                                  null &&
                                              profileController.profileInfo
                                                      ?.vehicleStatus ==
                                                  0)
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .paddingSizeDefault,
                                                vertical:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child:
                                                  const AddYourVehicleWidget(),
                                            ),

                                          // تحذير خارج المنطقة
                                          GetBuilder<OutOfZoneController>(
                                            builder: (outOfZoneController) {
                                              return outOfZoneController
                                                      .isDriverOutOfZone
                                                  ? Container(
                                                      margin: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: Dimensions
                                                            .paddingSizeDefault,
                                                        vertical: Dimensions
                                                            .paddingSizeSmall,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.orange
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            Colors.red
                                                                .withValues(
                                                                    alpha:
                                                                        0.05),
                                                          ],
                                                        ),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20),
                                                        border: Border.all(
                                                          color: Colors.orange
                                                              .withValues(
                                                                  alpha: 0.3),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: InkWell(
                                                        onTap: () => Get.to(() =>
                                                            const OutOfZoneMapScreen()),
                                                        child: Padding(
                                                          padding: const EdgeInsets
                                                              .all(Dimensions
                                                                  .paddingSizeDefault),
                                                          child: Row(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .spaceBetween,
                                                            children: [
                                                              Row(
                                                                children: [
                                                                  Container(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8),
                                                                    decoration:
                                                                        BoxDecoration(
                                                                      color: Colors
                                                                          .orange
                                                                          .withValues(
                                                                              alpha: 0.2),
                                                                      borderRadius:
                                                                          BorderRadius.circular(
                                                                              12),
                                                                    ),
                                                                    child: Icon(
                                                                      Icons
                                                                          .warning,
                                                                      size: 24,
                                                                      color: Colors
                                                                          .orange
                                                                          .shade700,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: Dimensions
                                                                          .paddingSizeDefault),
                                                                  Expanded(
                                                                    child:
                                                                        Column(
                                                                      crossAxisAlignment:
                                                                          CrossAxisAlignment
                                                                              .start,
                                                                      children: [
                                                                        Text(
                                                                          'you_are_out_of_zone'
                                                                              .tr,
                                                                          style:
                                                                              textBold.copyWith(
                                                                            fontSize:
                                                                                Dimensions.fontSizeDefault,
                                                                            color:
                                                                                Colors.orange.shade700,
                                                                          ),
                                                                        ),
                                                                        Text(
                                                                          'to_get_request_must'
                                                                              .tr,
                                                                          style:
                                                                              textRegular.copyWith(
                                                                            fontSize:
                                                                                12,
                                                                            color:
                                                                                Colors.orange.shade600,
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              Icon(
                                                                Icons
                                                                    .arrow_forward_ios,
                                                                color: Colors
                                                                    .orange
                                                                    .shade600,
                                                                size: 20,
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox();
                                            },
                                          ),

                                          // حالة المركبة المعلقة
                                          if (profileController
                                                      .profileInfo?.vehicle !=
                                                  null &&
                                              profileController.profileInfo
                                                      ?.vehicleStatus ==
                                                  1)
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .paddingSizeDefault,
                                                vertical:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child: VehiclePendingWidget(
                                                icon: Images.reward1,
                                                description:
                                                    'create_account_approve_description_vehicle'
                                                        .tr,
                                                title:
                                                    'registration_not_approve_yet_vehicle'
                                                        .tr,
                                              ),
                                            ),

                                          // قائمة الأنشطة
                                          if (Get.find<ProfileController>()
                                                  .profileInfo
                                                  ?.vehicle !=
                                              null)
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .paddingSizeDefault,
                                                vertical:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child:
                                                  const MyActivityListViewWidget(),
                                            ),

                                          const SizedBox(
                                              height: Dimensions
                                                  .paddingSizeDefault),

                                          // قسم الإحالة
                                          if (Get.find<SplashController>()
                                                  .config
                                                  ?.referralEarningStatus ??
                                              false)
                                            Container(
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                horizontal: Dimensions
                                                    .paddingSizeDefault,
                                                vertical:
                                                    Dimensions.paddingSizeSmall,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.1),
                                                    blurRadius: 15,
                                                    offset: const Offset(0, 5),
                                                  ),
                                                ],
                                              ),
                                              child:
                                                  const HomeReferralViewWidget(),
                                            ),

                                          const SizedBox(height: 100),
                                        ],
                                      )
                                    : const NotificationShimmerWidget();
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              // بطاقة الملف الشخصي المتحركة
              Positioned(
                top: GetPlatform.isIOS ? 120 : 90,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _profileCardAnimationController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _profileCardSlideAnimation.value),
                      child: Opacity(
                        opacity: _profileCardFadeAnimation.value,
                        child: GetBuilder<ProfileController>(
                          builder: (profileController) {
                            return GestureDetector(
                              onTap: () {
                                Get.to(() => const ProfileScreen());
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: Dimensions.paddingSizeDefault,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ProfileStatusCardWidget(
                                  profileController: profileController,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // زر عائم متحرك
        floatingActionButton: AnimatedBuilder(
          animation: _fabAnimationController,
          builder: (context, child) {
            return Transform.scale(
              scale: _fabScaleAnimation.value,
              child: Opacity(
                opacity: _fabFadeAnimation.value,
                child: GetBuilder<RideController>(
                  builder: (rideController) {
                    int ridingCount = rideController.getOnGoingRideCount();
                    int parcelCount =
                        rideController.parcelListModel?.totalSize ?? 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor,
                              Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: CustomMenuButtonWidget(
                          openForegroundColor: Colors.white,
                          closedBackgroundColor: Colors.transparent,
                          openBackgroundColor: Colors.transparent,
                          labelsBackgroundColor: Theme.of(context).cardColor,
                          speedDialChildren: <CustomMenuWidget>[
                            CustomMenuWidget(
                              child: const Icon(Icons.directions_run),
                              foregroundColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              label: 'ongoing_ride'.tr,
                              onPressed: () {
                                if (rideController
                                            .ongoingTrip![0].currentStatus ==
                                        'ongoing' ||
                                    rideController
                                            .ongoingTrip![0].currentStatus ==
                                        'accepted' ||
                                    (rideController.ongoingTrip![0]
                                                .currentStatus ==
                                            'completed' &&
                                        rideController.ongoingTrip![0]
                                                .paymentStatus ==
                                            'unpaid') ||
                                    (rideController.ongoingTrip![0].paidFare !=
                                            "0" &&
                                        rideController.ongoingTrip![0]
                                                .paymentStatus ==
                                            'unpaid')) {
                                  Get.find<RideController>()
                                      .getCurrentRideStatus(froDetails: true);
                                } else {
                                  showCustomSnackBar('no_trip_available'.tr);
                                }
                              },
                              closeSpeedDialOnPressed: false,
                            ),
                          ],
                          child: Padding(
                            padding: const EdgeInsets.all(
                                Dimensions.paddingSizeDefault),
                            child: Badge(
                              backgroundColor:
                                  Theme.of(context).primaryColorDark,
                              label: Text('${ridingCount + parcelCount}'),
                              child: Image.asset(
                                Images.ongoing,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
