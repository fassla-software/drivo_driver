import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/forgot_password_screen.dart';
import 'package:ride_sharing_user_app/features/auth/screens/sign_up_screen.dart';
import 'package:ride_sharing_user_app/features/dashboard/controllers/bottom_menu_controller.dart';
import 'package:ride_sharing_user_app/features/html/domain/html_enum_types.dart';
import 'package:ride_sharing_user_app/features/html/screens/policy_viewer_screen.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/ride/controllers/ride_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/app_constants.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen>
    with TickerProviderStateMixin {
  TextEditingController passwordController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  FocusNode phoneNode = FocusNode();
  FocusNode passwordNode = FocusNode();

  late AnimationController _logoAnimationController;
  late AnimationController _titleAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _buttonAnimationController;
  late AnimationController _footerAnimationController;

  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoRotationAnimation;
  late Animation<double> _titleSlideAnimation;
  late Animation<double> _titleFadeAnimation;
  late Animation<double> _formSlideAnimation;
  late Animation<double> _formFadeAnimation;
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonFadeAnimation;
  late Animation<double> _footerSlideAnimation;
  late Animation<double> _footerFadeAnimation;

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

    _footerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
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

    // تذييل متحرك
    _footerSlideAnimation = Tween<double>(
      begin: 30.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _footerAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _footerFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _footerAnimationController,
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
    Future.delayed(const Duration(milliseconds: 1200), () {
      _footerAnimationController.forward();
    });

    if (Get.find<AuthController>().getUserNumber().isNotEmpty) {
      phoneController.text = Get.find<AuthController>().getUserNumber();
    }
    passwordController.text = Get.find<AuthController>().getUserPassword();
    if (passwordController.text != '') {
      Get.find<AuthController>().setRememberMe();
    }
    if (Get.find<AuthController>().getLoginCountryCode().isNotEmpty) {
      Get.find<AuthController>().countryDialCode =
          Get.find<AuthController>().getLoginCountryCode();
    } else if (Get.find<SplashController>().config!.countryCode != null) {
      Get.find<AuthController>().countryDialCode = CountryCode.fromCountryCode(
              Get.find<SplashController>().config!.countryCode!)
          .dialCode!;
    }
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _titleAnimationController.dispose();
    _formAnimationController.dispose();
    _buttonAnimationController.dispose();
    _footerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (res, val) async {
        Get.find<BottomMenuController>().exitApp();
        return;
      },
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
            return GetBuilder<ProfileController>(builder: (profileController) {
              return GetBuilder<RideController>(builder: (rideController) {
                return GetBuilder<LocationController>(
                    builder: (locationController) {
                  return SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Column(
                          children: [
                            const SizedBox(height: 60),

                            // شعار متحرك
                            AnimatedBuilder(
                              animation: _logoAnimationController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _logoScaleAnimation.value,
                                  child: Transform.rotate(
                                    angle: _logoRotationAnimation.value,
                                    child: Container(
                                      padding: const EdgeInsets.all(30),
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
                                        Images.logoNameBlack,
                                        height: 80,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                  ),
                                );
                              },
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
                                          '${'welcome_to'.tr} ${AppConstants.appName}',
                                          style: textBold.copyWith(
                                            color: Colors.white,
                                            fontSize:
                                                Dimensions.fontSizeExtraLarge,
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
                                        Text(
                                          'log_in_message'.tr,
                                          style: textRegular.copyWith(
                                            color: Colors.white
                                                .withValues(alpha: 0.9),
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(height: 50),

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
                                      padding: const EdgeInsets.all(30),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(25),
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
                                                padding:
                                                    const EdgeInsets.all(12),
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
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Icon(
                                                  Icons.login_rounded,
                                                  color: Colors.white,
                                                  size: 28,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'log_in'.tr,
                                                      style: textBold.copyWith(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        fontSize: Dimensions
                                                            .fontSizeExtraLarge,
                                                      ),
                                                    ),
                                                    Text(
                                                      'log_in_message'.tr,
                                                      style:
                                                          textRegular.copyWith(
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

                                          const SizedBox(height: 30),

                                          // حقول الإدخال
                                          TextFieldWidget(
                                            hintText: 'phone'.tr,
                                            inputType: TextInputType.number,
                                            countryDialCode:
                                                authController.countryDialCode,
                                            controller: phoneController,
                                            focusNode: phoneNode,
                                            onCountryChanged:
                                                (CountryCode countryCode) {
                                              authController.countryDialCode =
                                                  countryCode.dialCode!;
                                              authController.setCountryCode(
                                                  countryCode.dialCode!);
                                            },
                                          ),
                                          const SizedBox(height: 20),

                                          TextFieldWidget(
                                            hintText: 'password'.tr,
                                            inputType: TextInputType.text,
                                            prefixIcon: Images.lock,
                                            inputAction: TextInputAction.done,
                                            focusNode: passwordNode,
                                            prefixHeight: 70,
                                            isPassword: true,
                                            controller: passwordController,
                                          ),

                                          const SizedBox(height: 20),

                                          // خيارات إضافية
                                          Row(
                                            children: [
                                              InkWell(
                                                onTap: () => authController
                                                    .toggleRememberMe(),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 22,
                                                      height: 22,
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: authController.isActiveRememberMe
                                                              ? Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                              : Colors.grey
                                                                  .withValues(
                                                                      alpha:
                                                                          0.5),
                                                          width: 2,
                                                        ),
                                                        color: authController
                                                                .isActiveRememberMe
                                                            ? Theme.of(context)
                                                                .primaryColor
                                                            : Colors
                                                                .transparent,
                                                      ),
                                                      child: authController
                                                              .isActiveRememberMe
                                                          ? Icon(
                                                              Icons.check,
                                                              size: 16,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Text(
                                                      'remember'.tr,
                                                      style:
                                                          textRegular.copyWith(
                                                        fontSize: Dimensions
                                                            .fontSizeDefault,
                                                        color: Theme.of(context)
                                                            .hintColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Spacer(),
                                              TextButton(
                                                onPressed: () => Get.to(() =>
                                                    const ForgotPasswordScreen()),
                                                child: Text(
                                                  'forgot_password'.tr,
                                                  style: textRegular.copyWith(
                                                    fontSize: Dimensions
                                                        .fontSizeDefault,
                                                    color: Theme.of(context)
                                                        .primaryColor,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 30),

                                          // زر متحرك
                                          AnimatedBuilder(
                                            animation:
                                                _buttonAnimationController,
                                            builder: (context, child) {
                                              return Transform.scale(
                                                scale:
                                                    _buttonScaleAnimation.value,
                                                child: Opacity(
                                                  opacity: _buttonFadeAnimation
                                                      .value,
                                                  child:
                                                      (authController
                                                                  .isLoading ||
                                                              authController
                                                                  .updateFcm ||
                                                              profileController
                                                                  .isLoading ||
                                                              rideController
                                                                  .isLoading ||
                                                              locationController
                                                                  .lastLocationLoading)
                                                          ? Center(
                                                              child: Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(20),
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                    Theme.of(
                                                                            context)
                                                                        .primaryColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.8),
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            50),
                                                              ),
                                                              child: SpinKitCircle(
                                                                  color: Colors
                                                                      .white,
                                                                  size: 30.0),
                                                            ))
                                                          : Container(
                                                              width: double
                                                                  .infinity,
                                                              height: 60,
                                                              decoration:
                                                                  BoxDecoration(
                                                                gradient:
                                                                    LinearGradient(
                                                                  colors: [
                                                                    Theme.of(
                                                                            context)
                                                                        .primaryColor,
                                                                    Theme.of(
                                                                            context)
                                                                        .primaryColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.8),
                                                                  ],
                                                                ),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            30),
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .primaryColor
                                                                        .withValues(
                                                                            alpha:
                                                                                0.4),
                                                                    blurRadius:
                                                                        15,
                                                                    offset:
                                                                        const Offset(
                                                                            0,
                                                                            8),
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Material(
                                                                color: Colors
                                                                    .transparent,
                                                                child: InkWell(
                                                                  borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                              30),
                                                                  onTap: () {
                                                                    String
                                                                        phone =
                                                                        phoneController
                                                                            .text;
                                                                    String
                                                                        password =
                                                                        passwordController
                                                                            .text;
                                                                    if (phone
                                                                        .isEmpty) {
                                                                      showCustomSnackBar(
                                                                          'phone_is_required'
                                                                              .tr);
                                                                      FocusScope.of(
                                                                              context)
                                                                          .requestFocus(
                                                                              phoneNode);
                                                                    } else if (!GetUtils.isPhoneNumber(
                                                                        authController.countryDialCode +
                                                                            phone)) {
                                                                      showCustomSnackBar(
                                                                          'phone_number_is_not_valid'
                                                                              .tr);
                                                                      FocusScope.of(
                                                                              context)
                                                                          .requestFocus(
                                                                              phoneNode);
                                                                    } else if (password
                                                                        .isEmpty) {
                                                                      showCustomSnackBar(
                                                                          'password_is_required'
                                                                              .tr);
                                                                      FocusScope.of(
                                                                              context)
                                                                          .requestFocus(
                                                                              passwordNode);
                                                                    } else if (password
                                                                            .length <
                                                                        8) {
                                                                      showCustomSnackBar(
                                                                          'minimum_password_length_is_8'
                                                                              .tr);
                                                                      FocusScope.of(
                                                                              context)
                                                                          .requestFocus(
                                                                              passwordNode);
                                                                    } else {
                                                                      authController.login(
                                                                          authController
                                                                              .countryDialCode,
                                                                          phone,
                                                                          password);
                                                                    }
                                                                  },
                                                                  child: Center(
                                                                    child: Text(
                                                                      'log_in'
                                                                          .tr,
                                                                      style: textBold
                                                                          .copyWith(
                                                                        color: Colors
                                                                            .white,
                                                                        fontSize:
                                                                            Dimensions.fontSizeLarge,
                                                                      ),
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

                            // تذييل متحرك
                            AnimatedBuilder(
                              animation: _footerAnimationController,
                              builder: (context, child) {
                                return Transform.translate(
                                  offset:
                                      Offset(0, _footerSlideAnimation.value),
                                  child: Opacity(
                                    opacity: _footerFadeAnimation.value,
                                    child: Column(
                                      children: [
                                        // قسم التسجيل الجديد
                                        if (Get.find<SplashController>()
                                            .config!
                                            .selfRegistration!)
                                          Column(
                                            children: [
                                              // فاصل أنيق
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: Container(
                                                      height: 1,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.white
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 20,
                                                      vertical: 10,
                                                    ),
                                                    child: Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 20,
                                                        vertical: 6,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white
                                                            .withValues(
                                                                alpha: 0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(15),
                                                      ),
                                                      child: Text(
                                                        'or'.tr,
                                                        style: textRegular
                                                            .copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Expanded(
                                                    child: Container(
                                                      height: 1,
                                                      decoration: BoxDecoration(
                                                        gradient:
                                                            LinearGradient(
                                                          colors: [
                                                            Colors.transparent,
                                                            Colors.white
                                                                .withValues(
                                                                    alpha: 0.3),
                                                            Colors.transparent,
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),

                                              const SizedBox(height: 20),

                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${'do_not_have_an_account'.tr} ',
                                                    style: textRegular.copyWith(
                                                      fontSize: Dimensions
                                                          .fontSizeDefault,
                                                      color: Colors.white
                                                          .withValues(
                                                              alpha: 0.9),
                                                    ),
                                                  ),
                                                  Container(
                                                    decoration: BoxDecoration(
                                                      border: Border(
                                                        bottom: BorderSide(
                                                          color: Colors.white,
                                                          width: 2,
                                                        ),
                                                      ),
                                                    ),
                                                    child: TextButton(
                                                      onPressed: () => Get.to(() =>
                                                          const SignUpScreen()),
                                                      style:
                                                          TextButton.styleFrom(
                                                        padding:
                                                            EdgeInsets.zero,
                                                        minimumSize:
                                                            const Size(50, 30),
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                      child: Text(
                                                        'sign_up'.tr,
                                                        style: textRegular
                                                            .copyWith(
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize: Dimensions
                                                              .fontSizeDefault,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        else
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "${'to_create_account'.tr} ",
                                                style: textRegular.copyWith(
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                  color: Colors.white
                                                      .withValues(alpha: 0.9),
                                                ),
                                              ),
                                              InkWell(
                                                onTap: () =>
                                                    Get.find<SplashController>()
                                                        .sendMailOrCall(
                                                  "tel:${Get.find<SplashController>().config?.businessContactPhone}",
                                                  false,
                                                ),
                                                child: Text(
                                                  "${'contact_support'.tr} ",
                                                  style: textRegular.copyWith(
                                                    color: Colors.white,
                                                    decoration: TextDecoration
                                                        .underline,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: Dimensions
                                                        .fontSizeDefault,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),

                                        const SizedBox(height: 30),

                                        // شروط الاستخدام
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.2),
                                              width: 1,
                                            ),
                                          ),
                                          child: InkWell(
                                            onTap: () => Get.to(() =>
                                                const PolicyViewerScreen(
                                                    htmlType: HtmlType
                                                        .termsAndConditions)),
                                            child: Text(
                                              "terms_and_condition".tr,
                                              style: textMedium.copyWith(
                                                color: Colors.white,
                                                fontSize:
                                                    Dimensions.fontSizeDefault,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      ],
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
                });
              });
            });
          }),
        ),
      ),
    );
  }
}
