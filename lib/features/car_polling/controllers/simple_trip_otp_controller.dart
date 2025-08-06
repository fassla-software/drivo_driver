import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../features/ride/domain/services/ride_service_interface.dart';

class SimpleTripOtpController extends GetxController {
  final RideServiceInterface rideServiceInterface;
  Function(String message, Color backgroundColor,
      {IconData icon, Duration duration})? onShowSnackBar;
  VoidCallback? onCloseDialog;

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

  void _showSnackBar(String message, bool isError) {
    print('=== Showing SnackBar: $message, isError: $isError ===');
    print('=== onShowSnackBar callback: ${onShowSnackBar != null} ===');

    if (onShowSnackBar != null) {
      onShowSnackBar!(
        message,
        isError ? Colors.red : Colors.green,
        icon: isError ? Icons.error_outline : Icons.check_circle,
      );
    } else {
      print('=== SnackBar callback is null! ===');
    }
  }

  Future<bool> matchOtp(String carpoolTripId, String otp) async {
    _isPinVerificationLoading = true;
    update();

    try {
      print(
          '=== Matching OTP for carpool_trip_id: $carpoolTripId, OTP: $otp ===');

      final response = await rideServiceInterface.matchOtp(carpoolTripId, otp);
      print('=== API Response: $response ===');
      print('=== Response Type: ${response.runtimeType} ===');

      // Handle different response types
      bool isSuccess = false;

      if (response is Map<String, dynamic>) {
        // Check response_code
        final responseCode = response["response_code"];
        print('=== Response Code: $responseCode ===');

        isSuccess = responseCode == "default_store_200" ||
            responseCode == "default_200" ||
            responseCode == "200";
      } else if (response is String) {
        // If response is a string, check if it contains success indicators
        isSuccess = response.contains("200") ||
            response.contains("success") ||
            response.contains("default_store_200");
      } else if (response.toString().contains("Response<dynamic>")) {
        // Handle Response object - check the body
        try {
          final responseBody = response.body;
          print('=== Response Body: $responseBody ===');
          print('=== Response Body Type: ${responseBody.runtimeType} ===');

          if (responseBody is Map<String, dynamic>) {
            final responseCode = responseBody["response_code"];
            print('=== Response Code from Body: $responseCode ===');

            isSuccess = responseCode == "default_store_200" ||
                responseCode == "default_200" ||
                responseCode == "200";
          } else if (responseBody is String) {
            isSuccess = responseBody.contains("default_store_200") ||
                responseBody.contains("default_200") ||
                responseBody.contains("200") ||
                responseBody.contains("Successfully added");
          }
        } catch (e) {
          print('=== Error accessing response body: $e ===');
          // Fallback to string check
          final responseString = response.toString();
          isSuccess = responseString.contains("default_store_200") ||
              responseString.contains("default_200") ||
              responseString.contains("200") ||
              responseString.contains("Successfully added");
        }
      }

      print('=== Is Success: $isSuccess ===');

      if (isSuccess) {
        clearVerificationCode();
        _showSnackBar('OTP verified successfully!', false);

        // Close dialog using callback
        if (onCloseDialog != null) {
          onCloseDialog!();
        }

        _isPinVerificationLoading = false;
        update();
        return true;
      } else {
        _isPinVerificationLoading = false;
        _showSnackBar('Failed to verify OTP. Please try again.', true);
        update();
        return false;
      }
    } catch (e) {
      print('=== Error matching OTP: $e ===');
      _isPinVerificationLoading = false;
      _showSnackBar('Error occurred while verifying OTP.', true);
      update();
      return false;
    }
  }
}
