import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/additional_sign_up_screen_1.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _titleAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _buttonAnimationController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;

  @override
  void initState() {
    super.initState();

    // تهيئة الرسوم المتحركة
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _titleAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _formAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _buttonAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // شعار متحرك
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    _logoRotationAnimation = Tween<double>(
      begin: -0.5,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.easeOutBack,
    ));

    // عنوان متحرك
    _titleSlideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _titleFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleAnimationController,
      curve: Curves.easeInOut,
    ));

    // نموذج متحرك
    _formSlideAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _formFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formAnimationController,
      curve: Curves.easeInOut,
    ));

    // زر متحرك
    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.elasticOut,
    ));

    _buttonFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonAnimationController,
      curve: Curves.easeInOut,
    ));

    // بدء الرسوم المتحركة
    _logoAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _titleAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _formAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      _buttonAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _titleAnimationController.dispose();
    _formAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withValues(alpha: 0.8),
                Theme.of(context).primaryColor.withValues(alpha: 0.6),
                Colors.white,
              ],
            ),
          ),
          child: GetBuilder<AuthController>(builder: (authController) {
            return Column(
              children: [
                // شريط التقدم المحسن
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(25),
                      bottomRight: Radius.circular(25),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Get.back(),
                        icon: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'signup_as_a_driver'.tr,
                              style: textBold.copyWith(
                                color: Colors.white,
                                fontSize: Dimensions.fontSizeLarge,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              '1_of_3'.tr,
                              style: textRegular.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding:
                          const EdgeInsets.all(Dimensions.paddingSizeLarge),
                      child: Column(
                        children: [
                          const SizedBox(height: 40),

                          // شعار متحرك
                          AnimatedBuilder(
                            animation: _logoAnimationController,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoScaleAnimation.value,
                                child: Transform.rotate(
                                  angle: _logoRotationAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.1),
                                          blurRadius: 30,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Image.asset(
                                      Get.isDarkMode
                                          ? Images.logoNameWhite
                                          : Images.logoNameBlack,
                                      height: 60,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),

                          // صورة التسجيل
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Image.asset(
                              Images.signUpScreenLogo,
                              width: 120,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // عنوان متحرك
                          AnimatedBuilder(
                            animation: _titleAnimationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _titleSlideAnimation.value),
                                child: Opacity(
                                  opacity: _titleFadeAnimation.value,
                                  child: Column(
                                    children: [
                                      Text(
                                        'choose_service'.tr,
                                        style: textBold.copyWith(
                                          color: Colors.white,
                                          fontSize: 24,
                                          shadows: [
                                            Shadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.3),
                                              offset: const Offset(0, 2),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 10),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 30),
                                        child: Text(
                                          'select_your_preferable_service'.tr,
                                          style: textRegular.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 40),

                          // نموذج متحرك
                          AnimatedBuilder(
                            animation: _formAnimationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(0, _formSlideAnimation.value),
                                child: Opacity(
                                  opacity: _formFadeAnimation.value,
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(25),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black
                                              .withValues(alpha: 0.15),
                                          blurRadius: 25,
                                          offset: const Offset(0, 10),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // عنوان النموذج
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(10),
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
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Icons.directions_car,
                                                color: Colors.white,
                                                size: 24,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    'service_selection'.tr,
                                                    style: textBold.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                    ),
                                                  ),
                                                  Text(
                                                    'select_your_preferable_service'
                                                        .tr,
                                                    style: textRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                      fontSize: Dimensions
                                                          .fontSizeSmall,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),

                                        const SizedBox(height: 25),

                                        // خيارات الخدمة
                                        Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              color: authController.isRideShare
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.3)
                                                  : Colors.grey
                                                      .withValues(alpha: 0.2),
                                              width: 2,
                                            ),
                                            color: authController.isRideShare
                                                ? Theme.of(context)
                                                    .primaryColor
                                                    .withValues(alpha: 0.05)
                                                : Colors.transparent,
                                          ),
                                          child: InkWell(
                                            onTap: () => authController
                                                .updateServiceType(true),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            child: Padding(
                                              padding: const EdgeInsets.all(15),
                                              child: Row(
                                                children: [
                                                  Container(
                                                    width: 24,
                                                    height: 24,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              6),
                                                      border: Border.all(
                                                        color: authController
                                                                .isRideShare
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                            : Colors.grey
                                                                .withValues(
                                                                    alpha: 0.5),
                                                        width: 2,
                                                      ),
                                                      color: authController
                                                              .isRideShare
                                                          ? Theme.of(context)
                                                              .primaryColor
                                                          : Colors.transparent,
                                                    ),
                                                    child: authController
                                                            .isRideShare
                                                        ? Icon(
                                                            Icons.check,
                                                            size: 16,
                                                            color: Colors.white,
                                                          )
                                                        : null,
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          'ride_share'.tr,
                                                          style:
                                                              textBold.copyWith(
                                                            fontSize: Dimensions
                                                                .fontSizeDefault,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 5),
                                                        Text(
                                                          'service_provide_text1'
                                                              .tr,
                                                          style: textRegular
                                                              .copyWith(
                                                            color: Theme.of(
                                                                    context)
                                                                .hintColor,
                                                            fontSize: Dimensions
                                                                .fontSizeSmall,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    Icons.directions_car,
                                                    color: authController
                                                            .isRideShare
                                                        ? Theme.of(context)
                                                            .primaryColor
                                                        : Colors.grey
                                                            .withValues(
                                                                alpha: 0.5),
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 20),

                                        // زر متحرك
                                        AnimatedBuilder(
                                          animation: _buttonAnimationController,
                                          builder: (context, child) {
                                            return Transform.scale(
                                              scale:
                                                  _buttonScaleAnimation.value,
                                              child: Opacity(
                                                opacity:
                                                    _buttonFadeAnimation.value,
                                                child: Container(
                                                  width: double.infinity,
                                                  height: 55,
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Theme.of(context)
                                                            .primaryColor,
                                                        Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.8),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.4),
                                                        blurRadius: 15,
                                                        offset:
                                                            const Offset(0, 8),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Material(
                                                    color: Colors.transparent,
                                                    child: InkWell(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              28),
                                                      onTap: () {
                                                        if (!authController
                                                                .isRideShare &&
                                                            !authController
                                                                .isParcelShare) {
                                                          showCustomSnackBar(
                                                              'required_to_select_service'
                                                                  .tr);
                                                        } else {
                                                          Get.to(() =>
                                                              const AdditionalSignUpScreen1());
                                                        }
                                                      },
                                                      child: Center(
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Text(
                                                              'next'.tr,
                                                              style: textBold
                                                                  .copyWith(
                                                                color: Colors
                                                                    .white,
                                                                fontSize: Dimensions
                                                                    .fontSizeLarge,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 8),
                                                            Icon(
                                                              Icons
                                                                  .arrow_forward,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
