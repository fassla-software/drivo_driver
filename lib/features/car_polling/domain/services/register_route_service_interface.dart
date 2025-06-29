import '../models/register_route_request_model.dart';
import '../models/register_route_response_model.dart';

abstract class RegisterRouteServiceInterface {
  Future<RegisterRouteResponseModel?> registerRoute(
      RegisterRouteRequestModel requestModel);
}
