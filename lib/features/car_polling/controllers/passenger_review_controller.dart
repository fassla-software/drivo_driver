import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../domain/models/passenger_review_request_model.dart';
import '../domain/services/passenger_review_service_interface.dart';

class PassengerReviewController extends GetxController {
  final PassengerReviewServiceInterface passengerReviewService;

  PassengerReviewController({required this.passengerReviewService});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<bool> reviewPassenger({
    required int carpoolPassengerId,
    required String decision,
  }) async {
    _isLoading = true;
    update();

    try {
      final request = PassengerReviewRequestModel(
        carpoolPassengerId: carpoolPassengerId,
        decision: decision,
      );

      final success = await passengerReviewService.reviewPassenger(request);

      if (success) {
        Get.showSnackbar(GetSnackBar(
          title: 'success'.tr,
          message: decision == 'accept'
              ? 'passenger_accepted_successfully'.tr
              : 'passenger_rejected_successfully'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ));
      } else {
        Get.showSnackbar(GetSnackBar(
          title: 'error'.tr,
          message: 'failed_to_review_passenger'.tr,
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.red,
        ));
      }

      _isLoading = false;
      update();
      return success;
    } catch (e) {
      _isLoading = false;
      update();

      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'something_went_wrong'.tr,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red,
      ));

      return false;
    }
  }

  Future<bool> acceptPassenger(int carpoolPassengerId) async {
    return await reviewPassenger(
      carpoolPassengerId: carpoolPassengerId,
      decision: 'accept',
    );
  }

  Future<bool> rejectPassenger(int carpoolPassengerId) async {
    return await reviewPassenger(
      carpoolPassengerId: carpoolPassengerId,
      decision: 'reject',
    );
  }
}
