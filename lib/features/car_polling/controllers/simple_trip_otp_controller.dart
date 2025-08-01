import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/api_checker.dart';
import '../../../features/ride/domain/services/ride_service_interface.dart';
import '../../../helper/display_helper.dart';

class SimpleTripOtpController extends GetxController {
  final RideServiceInterface rideServiceInterface;

  SimpleTripOtpController({required this.rideServiceInterface});

  String _verificationCode = '';
  String get verificationCode => _verificationCode;

  bool _isPinVerificationLoading = false;
  bool get isPinVerificationLoading => _isPinVerificationLoading;

  void updateVerificationCode(String code) {
    _verificationCode = code;
    update();
  }

  void clearVerificationCode() {
    _verificationCode = '';
    update();
  }

  Future<bool> matchOtp(String carpoolTripId, String otp) async {
    _isPinVerificationLoading = true;
    update();

    try {
      print(
          '=== Matching OTP for carpool_trip_id: $carpoolTripId, OTP: $otp ===');

      final response = await rideServiceInterface.matchOtp(carpoolTripId, otp);

      if (response["response_code"] == "default_store_200") {
        clearVerificationCode();
        showCustomSnackBar('otp_verified_successfully'.tr, isError: false);
        Get.back(); // Close the dialog
        _isPinVerificationLoading = false;
        update();
        return true;
      } else {
        _isPinVerificationLoading = false;
        ApiChecker.checkApi(response);
        update();
        return false;
      }
    } catch (e) {
      print('=== Error matching OTP: $e ===');
      _isPinVerificationLoading = false;
      showCustomSnackBar('failed_to_verify_otp'.tr, isError: true);
      update();
      return false;
    }
  }
}
