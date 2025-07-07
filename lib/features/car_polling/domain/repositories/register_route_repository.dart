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
      print('====> BEFORE API CALL - Request Model JSON:');
      print(requestModel.toJson());

      final response = await apiClient.postData(
        AppConstants
            .registerRouteUri, // Remove baseUrl since apiClient already has it
        requestModel.toJson(),
      );

      print('====> Register Route API Response Status: ${response.statusCode}');
      print('====> Register Route API Response Body: ${response.body}');
      print(
          '====> Register Route API Response StatusText: ${response.statusText}');

      // Handle successful response
      if (response.statusCode == 200 || response.statusCode == 201) {
        return RegisterRouteResponseModel.fromJson(response.body);
      }

      // Handle error responses with server messages
      if (response.body != null) {
        try {
          final errorResponse =
              RegisterRouteResponseModel.fromJson(response.body);
          return errorResponse; // Return the error response so controller can show server message
        } catch (e) {
          print('====> Error parsing response body: $e');
          // If parsing fails, create a generic error response
          return RegisterRouteResponseModel(
            success: false,
            message: 'Server returned status code: ${response.statusCode}',
            data: null,
          );
        }
      }

      // Fallback for no response body
      return RegisterRouteResponseModel(
        success: false,
        message: 'Request failed with status code: ${response.statusCode}',
        data: null,
      );
    } catch (e) {
      print('====> Exception in registerRoute: $e');
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
