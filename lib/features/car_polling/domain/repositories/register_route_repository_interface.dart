import '../models/register_route_request_model.dart';
import '../models/register_route_response_model.dart';
import '../../../../interface/repository_interface.dart';

abstract class RegisterRouteRepositoryInterface extends RepositoryInterface {
  Future<RegisterRouteResponseModel?> registerRoute(
      RegisterRouteRequestModel requestModel);
}
