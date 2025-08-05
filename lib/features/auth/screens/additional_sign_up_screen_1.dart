import 'package:country_code_picker/country_code_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/screens/additional_sign_up_screen_2.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class AdditionalSignUpScreen1 extends StatefulWidget {
  const AdditionalSignUpScreen1({super.key});

  @override
  State<AdditionalSignUpScreen1> createState() =>
      _AdditionalSignUpScreen1State();
}

class _AdditionalSignUpScreen1State extends State<AdditionalSignUpScreen1>
    with TickerProviderStateMixin {
  late AnimationController _titleAnimationController;
  late AnimationController _formAnimationController;
  late AnimationController _buttonAnimationController;

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
    _titleAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formAnimationController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      _buttonAnimationController.forward();
    });
  }

  @override
  void dispose() {
    _titleAnimationController.dispose();
    _formAnimationController.dispose();
    _buttonAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        child: SafeArea(
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
                              '2_of_3'.tr,
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
                          const SizedBox(height: 30),

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
                                        'provide_basic_info'.tr,
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
                                      Text(
                                        'enter_your_information'.tr,
                                        style: textRegular.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.9),
                                          fontSize: Dimensions.fontSizeDefault,
                                        ),
                                        textAlign: TextAlign.center,
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
                                                Icons.person_add,
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
                                                    'basic_information'.tr,
                                                    style: textBold.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                    ),
                                                  ),
                                                  Text(
                                                    'enter_your_information'.tr,
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

                                        // حقول الإدخال
                                        TextFieldTitleWidget(
                                            title: '${'first_name'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'first_name'.tr,
                                          capitalization:
                                              TextCapitalization.words,
                                          inputType: TextInputType.name,
                                          prefixIcon: Images.person,
                                          controller:
                                              authController.fNameController,
                                          focusNode: authController.fNameNode,
                                          nextFocus: authController.lNameNode,
                                          inputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'last_name'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'last_name'.tr,
                                          capitalization:
                                              TextCapitalization.words,
                                          inputType: TextInputType.name,
                                          prefixIcon: Images.person,
                                          controller:
                                              authController.lNameController,
                                          focusNode: authController.lNameNode,
                                          nextFocus: authController.phoneNode,
                                          inputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'phone'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'phone'.tr,
                                          inputType: TextInputType.number,
                                          countryDialCode:
                                              authController.countryDialCode,
                                          controller:
                                              authController.phoneController,
                                          focusNode: authController.phoneNode,
                                          nextFocus:
                                              authController.passwordNode,
                                          inputAction: TextInputAction.next,
                                          onCountryChanged:
                                              (CountryCode countryCode) {
                                            authController.countryDialCode =
                                                countryCode.dialCode!;
                                            authController.setCountryCode(
                                                countryCode.dialCode!);
                                            FocusScope.of(context).requestFocus(
                                                authController.phoneNode);
                                          },
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'password'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'password_hint'.tr,
                                          inputType: TextInputType.text,
                                          prefixIcon: Images.password,
                                          isPassword: true,
                                          controller:
                                              authController.passwordController,
                                          focusNode:
                                              authController.passwordNode,
                                          nextFocus: authController
                                              .confirmPasswordNode,
                                          inputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'confirm_password'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'enter_confirm_password'.tr,
                                          inputType: TextInputType.text,
                                          prefixIcon: Images.password,
                                          controller: authController
                                              .confirmPasswordController,
                                          focusNode: authController
                                              .confirmPasswordNode,
                                          nextFocus:
                                              authController.referralNode,
                                          inputAction: TextInputAction.next,
                                          isPassword: true,
                                        ),
                                        const SizedBox(height: 20),

                                        if (Get.find<SplashController>()
                                                .config
                                                ?.referralEarningStatus ??
                                            false) ...[
                                          TextFieldTitleWidget(
                                              title: 'referral_code'.tr),
                                          TextFieldWidget(
                                            hintText: 'referral_code'.tr,
                                            capitalization:
                                                TextCapitalization.words,
                                            inputType: TextInputType.text,
                                            prefixIcon: Images.referralIcon1,
                                            controller: authController
                                                .referralCodeController,
                                            focusNode:
                                                authController.referralNode,
                                            inputAction: TextInputAction.done,
                                          ),
                                          const SizedBox(height: 20),
                                        ],

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
                                                        String fName =
                                                            authController
                                                                .fNameController
                                                                .text;
                                                        String lName =
                                                            authController
                                                                .lNameController
                                                                .text;
                                                        String phone =
                                                            authController
                                                                .phoneController
                                                                .text
                                                                .trim();
                                                        String password =
                                                            authController
                                                                .passwordController
                                                                .text;
                                                        String confirmPassword =
                                                            authController
                                                                .confirmPasswordController
                                                                .text;

                                                        if (fName.isEmpty) {
                                                          showCustomSnackBar(
                                                              'first_name_is_required'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .fNameNode);
                                                        } else if (lName
                                                            .isEmpty) {
                                                          showCustomSnackBar(
                                                              'last_name_is_required'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .lNameNode);
                                                        } else if (phone
                                                            .isEmpty) {
                                                          showCustomSnackBar(
                                                              'phone_is_required'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .phoneNode);
                                                        } else if (!PhoneNumber
                                                                .parse(authController
                                                                        .countryDialCode +
                                                                    phone)
                                                            .isValid(
                                                                type: PhoneNumberType
                                                                    .mobile)) {
                                                          showCustomSnackBar(
                                                              'phone_number_is_not_valid'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .phoneNode);
                                                        } else if (password
                                                            .isEmpty) {
                                                          showCustomSnackBar(
                                                              'password_is_required'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .passwordNode);
                                                        } else if (password
                                                                .length <
                                                            8) {
                                                          showCustomSnackBar(
                                                              'minimum_password_length_is_8'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .passwordNode);
                                                        } else if (confirmPassword
                                                            .isEmpty) {
                                                          showCustomSnackBar(
                                                              'confirm_password_is_required'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .confirmPasswordNode);
                                                        } else if (password !=
                                                            confirmPassword) {
                                                          showCustomSnackBar(
                                                              'password_is_mismatch'
                                                                  .tr);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                                  authController
                                                                      .confirmPasswordNode);
                                                        } else {
                                                          Get.to(() =>
                                                              const AdditionalSignUpScreen2());
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
