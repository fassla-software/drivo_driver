

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ride_sharing_user_app/localization/localization_controller.dart';
import 'package:ride_sharing_user_app/util/images.dart';
import 'package:ride_sharing_user_app/features/home/widgets/activity_card_widget.dart';
import 'package:ride_sharing_user_app/features/profile/controllers/profile_controller.dart';
import 'package:ride_sharing_user_app/common_widgets/title_widget.dart';
import 'package:ride_sharing_user_app/util/dimensions.dart';
import 'package:ride_sharing_user_app/util/styles.dart';

class MyActivityListViewWidget extends StatefulWidget {
  const MyActivityListViewWidget({super.key});

  @override
  State<MyActivityListViewWidget> createState() => _MyActivityListViewWidgetState();
}

class _MyActivityListViewWidgetState extends State<MyActivityListViewWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<double>(
      begin: 50.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Padding(
              padding: const EdgeInsets.all(Dimensions.paddingSizeDefault),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان القسم
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              Theme.of(context).primaryColor.withValues(alpha: 0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.analytics,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: Dimensions.paddingSizeDefault),
                      Text(
                        'my_activity'.tr,
                        style: textBold.copyWith(
                          color: Theme.of(context).primaryColorDark,
                          fontSize: Dimensions.fontSizeLarge,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: Dimensions.paddingSizeDefault),

                  GetBuilder<ProfileController>(builder: (profileController) {
                    int activeSec = 0, offlineSec = 0, drivingSec = 0, idleSec = 0;
                    if(profileController.profileInfo != null && profileController.profileInfo!.timeTrack != null){
                      activeSec = profileController.profileInfo!.timeTrack!.totalOnline!.floor();
                      drivingSec = profileController.profileInfo!.timeTrack!.totalDriving!.floor();
                      idleSec = profileController.profileInfo!.timeTrack!.totalIdle!.floor();
                      offlineSec = profileController.profileInfo!.timeTrack!.totalOffline!.floor();
                    }
                    return profileController.profileInfo != null ?
                    SizedBox(
                      height: Get.find<LocalizationController>().isLtr? 100 : 105,
                      child: ListView(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        children: [
                          MyActivityCardWidget(
                            title: 'active',
                            icon: Images.activeHourIcon,
                            index: 0,
                            value: activeSec,
                            color: Theme.of(Get.context!).colorScheme.tertiary,
                          ),
                          MyActivityCardWidget(
                            title: 'on_driving',
                            icon: Images.onDrivingHourIcon,
                            index: 0,
                            value: drivingSec,
                            color: Theme.of(Get.context!).colorScheme.secondary,
                          ),
                          MyActivityCardWidget(
                            title: 'idle_time',
                            icon: Images.idleHourIcon,
                            index: 0,
                            value: idleSec,
                            color: Theme.of(Get.context!).colorScheme.tertiaryContainer,
                          ),
                          MyActivityCardWidget(
                            title: 'offline',
                            icon: Images.offlineHourIcon,
                            index: 0,
                            value: offlineSec,
                            color: Theme.of(Get.context!).colorScheme.secondaryContainer,
                          ),
                        ],
                      ),
                    ) : const SizedBox();
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
