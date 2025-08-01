import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../../util/dimensions.dart';
import '../../../util/styles.dart';
import '../../../helper/display_helper.dart';
import '../controllers/simple_trip_otp_controller.dart';

class SimpleTripOtpWidget extends StatelessWidget {
  final String carpoolTripId;
  final String passengerName;

  const SimpleTripOtpWidget({
    super.key,
    required this.carpoolTripId,
    required this.passengerName,
  });

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SimpleTripOtpController>(
      builder: (controller) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'enter_trip_otp'.tr,
              style: textBold.copyWith(fontSize: Dimensions.fontSizeLarge),
            ),
            const SizedBox(height: Dimensions.paddingSizeSmall),
            Text(
              'collect_the_otp_from_customer'.tr,
              style: textRegular.copyWith(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Dimensions.paddingSizeDefault),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Dimensions.paddingSizeExtraSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeDefault,
                        Dimensions.paddingSizeDefault,
                      ),
                      child: PinCodeTextField(
                        length: 4,
                        appContext: context,
                        obscureText: false,
                        showCursor: true,
                        keyboardType: TextInputType.number,
                        animationType: AnimationType.fade,
                        pinTheme: PinTheme(
                          shape: PinCodeFieldShape.box,
                          fieldHeight: 40,
                          fieldWidth: 40,
                          borderWidth: 1,
                          borderRadius: BorderRadius.circular(10),
                          selectedColor: Theme.of(context).primaryColor,
                          selectedFillColor:
                              Theme.of(context).primaryColor.withOpacity(.25),
                          inactiveFillColor:
                              Theme.of(context).disabledColor.withOpacity(.125),
                          inactiveColor:
                              Theme.of(context).disabledColor.withOpacity(.125),
                          activeColor:
                              Theme.of(context).primaryColor.withOpacity(.123),
                          activeFillColor:
                              Theme.of(context).primaryColor.withOpacity(.125),
                        ),
                        animationDuration: const Duration(milliseconds: 300),
                        backgroundColor: Colors.transparent,
                        enableActiveFill: true,
                        onChanged: controller.updateVerificationCode,
                        beforeTextPaste: (text) {
                          return true;
                        },
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () async {
                      if (controller.verificationCode.length == 4) {
                        await controller.matchOtp(
                            carpoolTripId, controller.verificationCode);
                      } else {
                        showCustomSnackBar("pin_code_is_required".tr);
                      }
                    },
                    child: controller.isPinVerificationLoading
                        ? const SizedBox(
                            width: 30,
                            height: 30,
                            child: CircularProgressIndicator(),
                          )
                        : Padding(
                            padding: const EdgeInsets.fromLTRB(
                              0,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                              Dimensions.paddingSizeDefault,
                            ),
                            child: SizedBox(
                              width: Dimensions.iconSizeLarge,
                              child: Icon(
                                Icons.arrow_forward,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
