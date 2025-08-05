import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/common_widgets/image_widget.dart';
import 'package:ride_sharing_user_app/common_widgets/loader_widget.dart';
import 'package:ride_sharing_user_app/features/location/controllers/location_controller.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/features/splash/controllers/splash_controller.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class ProfileStatusCardWidget extends StatefulWidget {
  final ProfileController profileController;
  const ProfileStatusCardWidget({super.key, required this.profileController});

  @override
  State<ProfileStatusCardWidget> createState() =>
      _ProfileStatusCardWidgetState();
}

class _ProfileStatusCardWidgetState extends State<ProfileStatusCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
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

    _animationController.forward();
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
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeDefault,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.white.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color:
                        Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                child: widget.profileController.profileInfo != null &&
                        widget.profileController.profileInfo!.firstName != null
                    ? Padding(
                        padding:
                            const EdgeInsets.all(Dimensions.paddingSizeLarge),
                        child: Row(
                          children: [
                            // صورة الملف الشخصي
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
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
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(25),
                                child: ImageWidget(
                                  width: 50,
                                  height: 50,
                                  image:
                                      '${Get.find<SplashController>().config!.imageBaseUrl!.profileImage}/${widget.profileController.profileInfo!.profileImage}',
                                ),
                              ),
                            ),
                            const SizedBox(
                                width: Dimensions.paddingSizeDefault),

                            // معلومات المستخدم
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${widget.profileController.profileInfo!.firstName!}  ${widget.profileController.profileInfo!.lastName!}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: textBold.copyWith(
                                      color: Theme.of(context).primaryColorDark,
                                      fontSize: Dimensions.fontSizeLarge,
                                    ),
                                  ),
                                  const SizedBox(
                                      height: Dimensions.paddingSizeExtraSmall),

                                  // مستوى المستخدم
                                  if (Get.find<SplashController>()
                                      .config!
                                      .levelStatus!)
                                    Container(
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
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.2),
                                          width: 1,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                          horizontal:
                                              Dimensions.paddingSizeExtraSmall,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              widget.profileController
                                                          .profileInfo!.level !=
                                                      null
                                                  ? widget.profileController
                                                      .profileInfo!.level!.name!
                                                  : '',
                                              style: textRegular.copyWith(
                                                color: Theme.of(context)
                                                    .primaryColorDark,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(
                                width: Dimensions.paddingSizeDefault),

                            // زر التبديل
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: FlutterSwitch(
                                width: 95.0,
                                height: 35.0,
                                valueFontSize: 12.0,
                                toggleSize: 30.0,
                                value: widget.profileController.isOnline == "1",
                                borderRadius: 30.0,
                                padding: 2,
                                activeColor: Theme.of(context).primaryColor,
                                inactiveColor:
                                    Colors.grey.withValues(alpha: 0.3),
                                toggleBorder: Border.all(
                                  width: 2,
                                  color: Colors.white,
                                ),
                                activeText: 'online'.tr,
                                inactiveText: 'offline'.tr,
                                activeTextColor: Colors.white,
                                inactiveTextColor: Colors.grey.shade600,
                                showOnOff: true,
                                activeTextFontWeight: FontWeight.w700,
                                inactiveTextFontWeight: FontWeight.w600,
                                toggleColor: Colors.white,
                                onToggle: (val) async {
                                  if (GetPlatform.isIOS) {
                                    Get.dialog(
                                      const LoaderWidget(),
                                      barrierDismissible: false,
                                    );
                                    await widget.profileController
                                        .profileOnlineOffline(val)
                                        .then((value) {
                                      if (value.statusCode == 200) {
                                        Get.back();
                                      }
                                    });
                                  } else {
                                    Get.find<LocationController>()
                                        .checkPermission(() async {
                                      Get.dialog(
                                        const LoaderWidget(),
                                        barrierDismissible: false,
                                      );
                                      await widget.profileController
                                          .profileOnlineOffline(val)
                                          .then((value) {
                                        if (value.statusCode == 200) {
                                          Get.back();
                                        }
                                        Get.back();
                                      });
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
          ),
        );
      },
    );
  }
}
