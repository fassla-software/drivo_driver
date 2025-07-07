import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../interface/repository_interface.dart';
import '../models/passenger_review_request_model.dart';

abstract class PassengerReviewRepositoryInterface
    implements RepositoryInterface {
  Future<Response> reviewPassenger(PassengerReviewRequestModel request);
}
