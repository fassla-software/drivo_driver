import '../models/passenger_review_request_model.dart';

abstract class PassengerReviewServiceInterface {
  Future<bool> reviewPassenger(PassengerReviewRequestModel request);
}
