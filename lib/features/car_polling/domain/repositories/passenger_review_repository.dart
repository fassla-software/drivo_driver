import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../data/api_client.dart';
import '../../../../util/app_constants.dart';
import '../models/passenger_review_request_model.dart';
import 'passenger_review_repository_interface.dart';

class PassengerReviewRepository implements PassengerReviewRepositoryInterface {
  final ApiClient apiClient;

  PassengerReviewRepository({required this.apiClient});

  @override
  Future<Response> reviewPassenger(PassengerReviewRequestModel request) async {
    return await apiClient.postData(
      AppConstants.reviewPassengerUri,
      request.toJson(),
    );
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int? id) {
    throw UnimplementedError();
  }

  @override
  Future get(String? id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int? id) {
    throw UnimplementedError();
  }
}
