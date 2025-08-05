import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/confirmation_dialog_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/chat/screens/chat_screen.dart';
import 'package:ride_sharing_user_app/features/help_and_support/screens/help_and_support_screen.dart';
import 'package:ride_sharing_user_app/features/html/domain/html_enum_types.dart';
import 'package:ride_sharing_user_app/features/html/screens/policy_viewer_screen.dart';
import 'package:ride_sharing_user_app/features/leaderboard/screens/leaderboard_screen.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/profile/screens/profile_screen.dart';
import 'package:ride_sharing_user_app/features/profile/widgets/profile_level_widget.dart';
import 'package:ride_sharing_user_app/features/refer_and_earn/screens/refer_and_earn_screen.dart';
import 'package:ride_sharing_user_app/features/review/screens/review_screen.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/setting/screens/setting_screen.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/features/wallet/screens/payment_info_screen.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({super.key});

  @override
  State<ProfileMenuScreen> createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _backgroundAnimationController;
  late AnimationController _contentAnimationController;
  
  late Animation<double> _backgroundFadeAnimation;
  late Animation<double> _contentSlideAnimation;
  late Animation<double> _contentFadeAnimation;

  @override
  void initState() {
    Get.find<RideController>().updateRoute(true, notify: false);
    
    _backgroundAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _contentAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _backgroundFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _backgroundAnimationController,
      curve: Curves.easeInOut,
    ));

    _contentSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeOutBack,
    ));

    _contentFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentAnimationController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
    super.initState();
  }

  void _startAnimations() async {
    await _backgroundAnimationController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _contentAnimationController.forward();
  }

  @override
  void dispose() {
    _backgroundAnimationController.dispose();
    _contentAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _backgroundAnimationController,
        _contentAnimationController,
      ]),
      builder: (context, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,
                  Colors.black.withValues(alpha: 0.95),
                  Colors.black.withValues(alpha: 0.9),
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Opacity(
              opacity: _backgroundFadeAnimation.value,
              child: Column(children: [
                const ProfileLevelWidgetWidget(),
                const SizedBox(height: 25),
                Expanded(
                  child: Transform.translate(
                    offset: Offset(0, _contentSlideAnimation.value),
                    child: Opacity(
                      opacity: _contentFadeAnimation.value,
                      child: SingleChildScrollView(
                        child: Column(children: [
                          ProfileMenuItem(
                            icon: Images.profileIcon,
                            title: 'profile',
                            onTap: () => Get.to(() => const ProfileScreen()),
                            index: 0,
                          ),
                          ProfileMenuItem(
                            icon: Images.message,
                            title: 'message',
                            onTap: () => Get.to(() => const ChatScreen()),
                            index: 1,
                          ),
                          ProfileMenuItem(
                            icon: Images.destinationIcon,
                            title: 'my_reviews',
                            onTap: () => Get.to(() => const ReviewScreen()),
                            index: 2,
                          ),
                          ProfileMenuItem(
                            icon: Images.leaderBoardIcon,
                            title: 'leader_board',
                            onTap: () => Get.to(() => const LeaderboardScreen()),
                            index: 3,
                          ),
                          if ((Get.find<SplashController>().config?.referralEarningStatus ??
                                  false) ||
                              ((Get.find<ProfileController>()
                                          .profileInfo
                                          ?.wallet
                                          ?.referralEarn ??
                                      0) >
                                  0))
                            ProfileMenuItem(
                              icon: Images.referralIcon1,
                              title: 'refer&earn',
                              onTap: () => Get.to(() => const ReferAndEarnScreen()),
                              index: 4,
                            ),
                          ProfileMenuItem(
                            icon: Images.leaderBoardIcon,
                            title: 'add_withdraw_info',
                            onTap: () => Get.to(() => const PaymentInfoScreen()),
                            index: 5,
                          ),
                          ProfileMenuItem(
                            icon: Images.helpAndSupportIcon,
                            title: 'help_and_support',
                            onTap: () => Get.to(() => const HelpAndSupportScreen()),
                            index: 6,
                          ),
                          ProfileMenuItem(
                            icon: Images.setting,
                            title: 'setting',
                            onTap: () => Get.to(() => const SettingScreen()),
                            index: 7,
                          ),
                          ProfileMenuItem(
                            icon: Images.privacyPolicy,
                            title: 'privacy_policy',
                            onTap: () => Get.to(() => PolicyViewerScreen(
                                  htmlType: HtmlType.privacyPolicy,
                                  image: Get.find<SplashController>()
                                          .config
                                          ?.privacyPolicy
                                          ?.image ??
                                      '',
                                )),
                            index: 8,
                          ),
                          ProfileMenuItem(
                            icon: Images.termsAndCondition,
                            title: 'terms_and_condition',
                            onTap: () => Get.to(() => PolicyViewerScreen(
                                  htmlType: HtmlType.termsAndConditions,
                                  image: Get.find<SplashController>()
                                          .config
                                          ?.termsAndConditions
                                          ?.image ??
                                      '',
                                )),
                            index: 9,
                          ),
                          ProfileMenuItem(
                            icon: Images.termsAndCondition,
                            title: 'refund_policy',
                            onTap: () => Get.to(() => PolicyViewerScreen(
                                  htmlType: HtmlType.refundPolicy,
                                  image: Get.find<SplashController>()
                                          .config
                                          ?.refundPolicy
                                          ?.image ??
                                      '',
                                )),
                            index: 10,
                          ),
                          ProfileMenuItem(
                            icon: Images.privacyPolicy,
                            title: 'legal',
                            onTap: () => Get.to(() => PolicyViewerScreen(
                                  htmlType: HtmlType.legal,
                                  image:
                                      Get.find<SplashController>().config?.legal?.image ?? '',
                                )),
                            index: 11,
                          ),
                          ProfileMenuItem(
                            icon: Images.logOutIcon,
                            title: 'logout',
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    return GetBuilder<AuthController>(
                                        builder: (authController) {
                                      return ConfirmationDialogWidget(
                                        icon: Images.logOutIcon,
                                        loading: authController.logging,
                                        title: 'logout'.tr,
                                        description: 'do_you_want_to_log_out_this_account'.tr,
                                        onYesPressed: () {
                                          authController.logOut();
                                        },
                                      );
                                    });
                                  });
                            },
                            index: 12,
                          ),
                          ProfileMenuItem(
                            icon: Images.logOutIcon,
                            title: 'permanently_delete_account'.tr,
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (_) {
                                    return GetBuilder<AuthController>(
                                        builder: (authController) {
                                      return ConfirmationDialogWidget(
                                        icon: Images.logOutIcon,
                                        loading: authController.logging,
                                        title: 'delete_account'.tr,
                                        description: 'permanently_delete_confirm_msg'.tr,
                                        onYesPressed: () {
                                          authController.permanentDelete();
                                        },
                                      );
                                    });
                                  });
                            },
                            index: 13,
                          ),
                          const SizedBox(height: 100)
                        ]),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class ProfileMenuItem extends StatefulWidget {
  final String icon;
  final String title;
  final Function()? onTap;
  final int index;
  const ProfileMenuItem({
    super.key, 
    required this.icon, 
    required this.title, 
    this.onTap,
    required this.index,
  });

  @override
  State<ProfileMenuItem> createState() => _ProfileMenuItemState();
}

class _ProfileMenuItemState extends State<ProfileMenuItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 800 + (widget.index * 100)),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    Future.delayed(Duration(milliseconds: widget.index * 150), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.translate(
            offset: Offset(0, _slideAnimation.value),
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: InkWell(
                onTap: widget.onTap,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: Dimensions.paddingSizeDefault,
                    vertical: Dimensions.paddingSizeExtraSmall,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.white.withValues(alpha: 0.05),
                        Colors.white.withValues(alpha: 0.02),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                    borderRadius: BorderRadius.circular(Dimensions.paddingSizeDefault),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(Dimensions.paddingSizeSmall),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(Dimensions.paddingSizeSmall),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: SizedBox(
                          width: Dimensions.iconSizeLarge,
                          child: Image.asset(widget.icon, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Expanded(
                        child: Text(
                          widget.title.tr,
                          style: textSemiBold.copyWith(
                            color: Colors.white, 
                            fontSize: Dimensions.fontSizeLarge,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white.withValues(alpha: 0.7),
                          size: 16,
                        ),
                      ),
                    ]),
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
