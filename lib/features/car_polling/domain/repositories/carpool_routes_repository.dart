import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../data/api_client.dart';
import '../../../../util/app_constants.dart';
import 'carpool_routes_repository_interface.dart';

class CarpoolRoutesRepository implements CarpoolRoutesRepositoryInterface {
  final ApiClient apiClient;

  CarpoolRoutesRepository({required this.apiClient});

  @override
  Future<Response> getCarpoolRoutes({int offset = 1, int limit = 10}) async {
    return await apiClient.getData(
      '${AppConstants.carpoolRoutesUri}?limit=$limit&offset=$offset',
    );
  }

  @override
  Future add(value) {
    throw UnimplementedError();
  }

  @override
  Future delete(int id) {
    throw UnimplementedError();
  }

  @override
  Future get(String id) {
    throw UnimplementedError();
  }

  @override
  Future getList({int? offset = 1}) {
    throw UnimplementedError();
  }

  @override
  Future update(Map<String, dynamic> body, int id) {
    throw UnimplementedError();
  }
}
