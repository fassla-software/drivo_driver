import '../models/register_route_request_model.dart';
import '../models/register_route_response_model.dart';
import '../repositories/register_route_repository_interface.dart';
import 'register_route_service_interface.dart';

class RegisterRouteService implements RegisterRouteServiceInterface {
  final RegisterRouteRepositoryInterface registerRouteRepositoryInterface;

  RegisterRouteService({required this.registerRouteRepositoryInterface});

  @override
  Future<RegisterRouteResponseModel?> registerRoute(
      RegisterRouteRequestModel requestModel) async {
    return await registerRouteRepositoryInterface.registerRoute(requestModel);
  }
}
