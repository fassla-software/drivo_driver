import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/helper/display_helper.dart';
import 'package:ride_sharing_user_app/helper/email_checker.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/util/styles.dart';
import 'package:ride_sharing_user_app/features/auth/controllers/auth_controller.dart';
import 'package:ride_sharing_user_app/features/auth/domain/models/signup_body.dart';
import 'package:ride_sharing_user_app/features/auth/widgets/text_field_title_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/text_field_widget.dart';

class AdditionalSignUpScreen2 extends StatefulWidget {
  const AdditionalSignUpScreen2({super.key});

  @override
  State<AdditionalSignUpScreen2> createState() =>
      _AdditionalSignUpScreen2State();
}

class _AdditionalSignUpScreen2State extends State<AdditionalSignUpScreen2>
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
                              '3_of_3'.tr,
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
                                        'provide_your_identity'.tr,
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
                                        'this_information_will_help'.tr,
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
                                                Icons.verified_user,
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
                                                    'identity_verification'.tr,
                                                    style: textBold.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                      fontSize: Dimensions
                                                          .fontSizeLarge,
                                                    ),
                                                  ),
                                                  Text(
                                                    'this_information_will_help'
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

                                        // صورة الملف الشخصي
                                        Center(
                                          child: Container(
                                            height: 100,
                                            width: 100,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                width: 3,
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Theme.of(context)
                                                      .primaryColor
                                                      .withValues(alpha: 0.3),
                                                  blurRadius: 15,
                                                  offset: const Offset(0, 5),
                                                ),
                                              ],
                                            ),
                                            child: Stack(
                                              alignment:
                                                  AlignmentDirectional.center,
                                              clipBehavior: Clip.none,
                                              children: [
                                                authController
                                                            .pickedProfileFile ==
                                                        null
                                                    ? ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(50),
                                                        child: Container(
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.grey
                                                                .withValues(
                                                                    alpha: 0.1),
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        50),
                                                          ),
                                                          child: Icon(
                                                            Icons.person,
                                                            size: 50,
                                                            color: Theme.of(
                                                                    context)
                                                                .primaryColor
                                                                .withValues(
                                                                    alpha: 0.5),
                                                          ),
                                                        ),
                                                      )
                                                    : CircleAvatar(
                                                        radius: 50,
                                                        backgroundImage: FileImage(
                                                            File(authController
                                                                .pickedProfileFile!
                                                                .path)),
                                                      ),
                                                Positioned(
                                                  right: 5,
                                                  bottom: -3,
                                                  child: InkWell(
                                                    onTap: () => authController
                                                        .pickImage(false, true),
                                                    child: Container(
                                                      decoration: BoxDecoration(
                                                        color: Theme.of(context)
                                                            .primaryColor,
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: Colors.black
                                                                .withValues(
                                                                    alpha: 0.2),
                                                            blurRadius: 8,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      padding:
                                                          const EdgeInsets.all(
                                                              8),
                                                      child: const Icon(
                                                        Icons
                                                            .camera_enhance_rounded,
                                                        color: Colors.white,
                                                        size: 16,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 25),

                                        // حقول الإدخال
                                        TextFieldTitleWidget(
                                            title: '${'email'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'email'.tr,
                                          inputType: TextInputType.emailAddress,
                                          prefixIcon: Images.email,
                                          controller:
                                              authController.emailController,
                                          focusNode: authController.emailNode,
                                          nextFocus: authController.addressNode,
                                          inputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'address'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'address'.tr,
                                          capitalization:
                                              TextCapitalization.words,
                                          inputType: TextInputType.text,
                                          prefixIcon: Images.location,
                                          controller:
                                              authController.addressController,
                                          focusNode: authController.addressNode,
                                          nextFocus:
                                              authController.identityNumberNode,
                                          inputAction: TextInputAction.next,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'identity_type'.tr}*'),
                                        Container(
                                          height: 55,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: Dimensions
                                                  .paddingSizeDefault),
                                          decoration: BoxDecoration(
                                            color: Colors.grey
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              width: 1,
                                              color: Theme.of(context)
                                                  .hintColor
                                                  .withValues(alpha: 0.3),
                                            ),
                                          ),
                                          child: DropdownButton<String>(
                                            hint: authController.identityType ==
                                                    ''
                                                ? Text(
                                                    'select_identity_type'.tr,
                                                    style: textRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .hintColor,
                                                    ),
                                                  )
                                                : Text(
                                                    authController
                                                        .identityType.tr,
                                                    style: textRegular.copyWith(
                                                      color: Theme.of(context)
                                                          .primaryColor,
                                                    ),
                                                  ),
                                            items: authController
                                                .identityTypeList
                                                .map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(
                                                  value.tr,
                                                  style: textRegular.copyWith(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyMedium!
                                                        .color,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                            onChanged: (val) {
                                              authController
                                                  .setIdentityType(val!);
                                            },
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title:
                                                '${'identification_number'.tr}*'),
                                        TextFieldWidget(
                                          hintText: 'Ex: 12345',
                                          inputType: TextInputType.text,
                                          prefixIcon: Images.identity,
                                          controller: authController
                                              .identityNumberController,
                                          focusNode:
                                              authController.identityNumberNode,
                                          inputAction: TextInputAction.done,
                                        ),
                                        const SizedBox(height: 20),

                                        TextFieldTitleWidget(
                                            title: '${'identity_image'.tr}*'),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: Colors.grey
                                                .withValues(alpha: 0.05),
                                            borderRadius:
                                                BorderRadius.circular(15),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .hintColor
                                                  .withValues(alpha: 0.3),
                                              width: 1,
                                            ),
                                          ),
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemCount: authController
                                                        .identityImages
                                                        .length >=
                                                    2
                                                ? 2
                                                : authController
                                                        .identityImages.length +
                                                    1,
                                            itemBuilder:
                                                (BuildContext context, index) {
                                              return index ==
                                                      authController
                                                          .identityImages.length
                                                  ? GestureDetector(
                                                      onTap: () =>
                                                          authController
                                                              .pickImage(
                                                                  false, false),
                                                      child: DottedBorder(
                                                        strokeWidth: 2,
                                                        dashPattern: const [
                                                          10,
                                                          5
                                                        ],
                                                        color: Theme.of(context)
                                                            .primaryColor
                                                            .withValues(
                                                                alpha: 0.5),
                                                        borderType:
                                                            BorderType.RRect,
                                                        radius: const Radius
                                                            .circular(Dimensions
                                                                .paddingSizeSmall),
                                                        child: Container(
                                                          height: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4.3,
                                                          width: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width,
                                                          decoration:
                                                              BoxDecoration(
                                                            color: Colors.grey
                                                                .withValues(
                                                                    alpha:
                                                                        0.05),
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    Dimensions
                                                                        .paddingSizeSmall),
                                                          ),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              Icon(
                                                                Icons
                                                                    .add_a_photo,
                                                                color: Theme.of(
                                                                        context)
                                                                    .primaryColor
                                                                    .withValues(
                                                                        alpha:
                                                                            0.5),
                                                                size: 30,
                                                              ),
                                                              const SizedBox(
                                                                  height: 5),
                                                              Text(
                                                                'add_identity_image'
                                                                    .tr,
                                                                style: textRegular
                                                                    .copyWith(
                                                                  color: Theme.of(
                                                                          context)
                                                                      .hintColor,
                                                                  fontSize:
                                                                      Dimensions
                                                                          .fontSizeSmall,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : Stack(
                                                      children: [
                                                        Padding(
                                                          padding: const EdgeInsets
                                                              .only(
                                                              bottom: Dimensions
                                                                  .paddingSizeSmall),
                                                          child: Container(
                                                            decoration:
                                                                BoxDecoration(
                                                              color:
                                                                  Colors.white,
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                              boxShadow: [
                                                                BoxShadow(
                                                                  color: Colors
                                                                      .black
                                                                      .withValues(
                                                                          alpha:
                                                                              0.1),
                                                                  blurRadius:
                                                                      10,
                                                                  offset:
                                                                      const Offset(
                                                                          0, 3),
                                                                ),
                                                              ],
                                                            ),
                                                            child: ClipRRect(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          15),
                                                              child: Image.file(
                                                                File(authController
                                                                    .identityImages[
                                                                        index]
                                                                    .path),
                                                                width: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width,
                                                                height: MediaQuery.of(
                                                                            context)
                                                                        .size
                                                                        .width /
                                                                    4.3,
                                                                fit: BoxFit
                                                                    .cover,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                        Positioned(
                                                          top: 5,
                                                          right: 5,
                                                          child: InkWell(
                                                            onTap: () =>
                                                                authController
                                                                    .removeImage(
                                                                        index),
                                                            child: Container(
                                                              decoration:
                                                                  BoxDecoration(
                                                                color:
                                                                    Colors.red,
                                                                shape: BoxShape
                                                                    .circle,
                                                                boxShadow: [
                                                                  BoxShadow(
                                                                    color: Colors
                                                                        .black
                                                                        .withValues(
                                                                            alpha:
                                                                                0.2),
                                                                    blurRadius:
                                                                        8,
                                                                    offset:
                                                                        const Offset(
                                                                            0,
                                                                            2),
                                                                  ),
                                                                ],
                                                              ),
                                                              child:
                                                                  const Padding(
                                                                padding:
                                                                    EdgeInsets
                                                                        .all(
                                                                            4.0),
                                                                child: Icon(
                                                                  Icons
                                                                      .delete_forever_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 16,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                            },
                                          ),
                                        ),

                                        const SizedBox(height: 30),

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
                                                child: authController.isLoading
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
                                                            color: Colors.white,
                                                            size: 30.0,
                                                          ),
                                                        ),
                                                      )
                                                    : Container(
                                                        width: double.infinity,
                                                        height: 55,
                                                        decoration:
                                                            BoxDecoration(
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                              Theme.of(context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.8),
                                                            ],
                                                          ),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(28),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor
                                                                  .withValues(
                                                                      alpha:
                                                                          0.4),
                                                              blurRadius: 15,
                                                              offset:
                                                                  const Offset(
                                                                      0, 8),
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
                                                                        28),
                                                            onTap: () async {
                                                              String email =
                                                                  authController
                                                                      .emailController
                                                                      .text;
                                                              String address =
                                                                  authController
                                                                      .addressController
                                                                      .text;
                                                              String
                                                                  identityNumber =
                                                                  authController
                                                                      .identityNumberController
                                                                      .text;
                                                              if (authController
                                                                      .pickedProfileFile ==
                                                                  null) {
                                                                showCustomSnackBar(
                                                                    'profile_image_is_required'
                                                                        .tr);
                                                              } else if (email
                                                                  .isEmpty) {
                                                                showCustomSnackBar(
                                                                    'email_is_required'
                                                                        .tr);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        authController
                                                                            .emailNode);
                                                              } else if (EmailChecker
                                                                  .isNotValid(
                                                                      email)) {
                                                                showCustomSnackBar(
                                                                    'enter_valid_email_address'
                                                                        .tr);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        authController
                                                                            .emailNode);
                                                              } else if (address
                                                                  .isEmpty) {
                                                                showCustomSnackBar(
                                                                    'address_is_required'
                                                                        .tr);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        authController
                                                                            .addressNode);
                                                              } else if (identityNumber
                                                                  .isEmpty) {
                                                                showCustomSnackBar(
                                                                    'identity_number_is_required'
                                                                        .tr);
                                                                FocusScope.of(
                                                                        context)
                                                                    .requestFocus(
                                                                        authController
                                                                            .identityNumberNode);
                                                              } else if (authController
                                                                  .identityImages
                                                                  .isEmpty) {
                                                                showCustomSnackBar(
                                                                    'identity_image_is_required'
                                                                        .tr);
                                                              } else if (authController
                                                                  .identityType
                                                                  .isEmpty) {
                                                                showCustomSnackBar(
                                                                    'identity_type_is_required'
                                                                        .tr);
                                                              } else {
                                                                List<String>
                                                                    services =
                                                                    [];
                                                                if (authController
                                                                    .isRideShare) {
                                                                  services.add(
                                                                      'ride_request');
                                                                }
                                                                if (authController
                                                                    .isParcelShare) {
                                                                  services.add(
                                                                      'parcel');
                                                                }
                                                                String?
                                                                    deviceToken =
                                                                    await FirebaseMessaging
                                                                        .instance
                                                                        .getToken();
                                                                SignUpBody
                                                                    signUpBody =
                                                                    SignUpBody(
                                                                  email: email,
                                                                  address:
                                                                      address,
                                                                  identityNumber:
                                                                      identityNumber,
                                                                  identificationType:
                                                                      authController
                                                                          .identityType,
                                                                  fName: authController
                                                                      .fNameController
                                                                      .text,
                                                                  lName: authController
                                                                      .lNameController
                                                                      .text,
                                                                  phone: authController
                                                                          .countryDialCode +
                                                                      authController
                                                                          .phoneController
                                                                          .text,
                                                                  password:
                                                                      authController
                                                                          .passwordController
                                                                          .text,
                                                                  confirmPassword:
                                                                      authController
                                                                          .confirmPasswordController
                                                                          .text,
                                                                  deviceToken:
                                                                      authController
                                                                          .getDeviceToken(),
                                                                  services:
                                                                      services,
                                                                  referralCode:
                                                                      authController
                                                                          .referralCodeController
                                                                          .text
                                                                          .trim(),
                                                                  fcmToken:
                                                                      deviceToken,
                                                                );
                                                                authController.register(
                                                                    authController
                                                                        .countryDialCode,
                                                                    signUpBody);
                                                              }
                                                            },
                                                            child: Center(
                                                              child: Row(
                                                                mainAxisAlignment:
                                                                    MainAxisAlignment
                                                                        .center,
                                                                children: [
                                                                  Text(
                                                                    'submit'.tr,
                                                                    style: textBold
                                                                        .copyWith(
                                                                      color: Colors
                                                                          .white,
                                                                      fontSize:
                                                                          Dimensions
                                                                              .fontSizeLarge,
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      width: 8),
                                                                  Icon(
                                                                    Icons
                                                                        .check_circle,
                                                                    color: Colors
                                                                        .white,
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
