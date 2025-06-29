import '../../../../data/api_client.dart';
import '../models/register_route_request_model.dart';
import '../models/register_route_response_model.dart';
import 'register_route_repository_interface.dart';
import '../../../../util/app_constants.dart';

class RegisterRouteRepository implements RegisterRouteRepositoryInterface {
  final ApiClient apiClient;

  RegisterRouteRepository({required this.apiClient});

  @override
  Future<RegisterRouteResponseModel?> registerRoute(
      RegisterRouteRequestModel requestModel) async {
    try {
      final response = await apiClient.postData(
        '${AppConstants.baseUrl}${AppConstants.registerRouteUri}',
        requestModel.toJson(),
      );

      if (response.statusCode == 200) {
        return RegisterRouteResponseModel.fromJson(response.body);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    // TODO: implement delete
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    // TODO: implement get
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset}) {
    // TODO: implement getList
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    // TODO: implement update
    throw UnimplementedError();
  }
}
