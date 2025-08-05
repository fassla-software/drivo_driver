import '../../../../data/api_client.dart';
import '../models/register_route_request_model.dart';
import '../models/register_route_response_model.dart';
import 'register_route_repository_interface.dart';
import '../../../../util/app_constants.dart';
import 'package:get/get.dart';

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

      // Handle successful response (200, 201, 202)
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        try {
          final responseModel =
              RegisterRouteResponseModel.fromJson(response.body);
          // Ensure success is true for successful status codes
          if (responseModel.success == false) {
            return RegisterRouteResponseModel(
              success: true,
              message: responseModel.message.isNotEmpty
                  ? responseModel.message
                  : 'Route registered successfully',
              routeId: responseModel.routeId,
              data: responseModel.data,
            );
          }
          return responseModel;
        } catch (e) {
          print('====> Error parsing successful response: $e');
          return RegisterRouteResponseModel(
            success: true,
            message: 'Route registered successfully',
            data: response.body,
          );
        }
      }

      // Handle client errors (4xx)
      if (response.statusCode! >= 400 && response.statusCode! < 500) {
        if (response.body != null) {
          try {
            final errorResponse =
                RegisterRouteResponseModel.fromJson(response.body);
            return errorResponse;
          } catch (e) {
            print('====> Error parsing error response: $e');
            String errorMessage =
                _getErrorMessageByStatusCode(response.statusCode!);
            return RegisterRouteResponseModel(
              success: false,
              message: errorMessage,
              data: response.body,
            );
          }
        } else {
          String errorMessage =
              _getErrorMessageByStatusCode(response.statusCode!);
          return RegisterRouteResponseModel(
            success: false,
            message: errorMessage,
            data: null,
          );
        }
      }

      // Handle server errors (5xx)
      if (response.statusCode! >= 500) {
        return RegisterRouteResponseModel(
          success: false,
          message: 'server_error_occurred'.tr,
          data: response.body,
        );
      }

      // Handle other status codes
      return RegisterRouteResponseModel(
        success: false,
        message: 'unexpected_response_status_${response.statusCode}'.tr,
        data: response.body,
      );
    } catch (e) {
      print('====> Exception in registerRoute: $e');
      rethrow;
    }
  }

  // Helper method to get error messages based on status code
  String _getErrorMessageByStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'bad_request'.tr;
      case 401:
        return 'unauthorized_access'.tr;
      case 403:
        return 'forbidden_access'.tr;
      case 404:
        return 'resource_not_found'.tr;
      case 409:
        return 'conflict_error'.tr;
      case 422:
        return 'validation_error'.tr;
      case 429:
        return 'too_many_requests'.tr;
      default:
        return 'request_failed_with_status_$statusCode'.tr;
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
