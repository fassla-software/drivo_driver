import '../models/passenger_review_request_model.dart';
import '../repositories/passenger_review_repository_interface.dart';
import 'passenger_review_service_interface.dart';

class PassengerReviewService implements PassengerReviewServiceInterface {
  final PassengerReviewRepositoryInterface passengerReviewRepository;

  PassengerReviewService({required this.passengerReviewRepository});

  @override
  Future<bool> reviewPassenger(PassengerReviewRequestModel request) async {
    try {
      final response = await passengerReviewRepository.reviewPassenger(request);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
