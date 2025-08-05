import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../data/api_client.dart';
import '../../../../util/app_constants.dart';
import 'current_trips_repository_interface.dart';

class CurrentTripsRepository implements CurrentTripsRepositoryInterface {
  final ApiClient apiClient;

  CurrentTripsRepository({required this.apiClient});

  @override
  Future<Response> getCurrentTripsWithPassengers() async {
    print('=== Repository: getCurrentTripsWithPassengers called ===');
    print(
        '=== Repository: API URL: ${AppConstants.currentTripsWithPassengersUri} ===');
    final response =
        await apiClient.getData(AppConstants.currentTripsWithPassengersUri);
    print(
        '=== Repository: Response received with status: ${response.statusCode} ===');
    return response;
  }

  @override
  Future<Response> startTrip(int carpoolRouteId) async {
    print('=== Repository: startTrip called with routeId: $carpoolRouteId ===');
    print('=== Repository: API URL: ${AppConstants.startTripUri} ===');

    final Map<String, dynamic> body = {
      'carpool_route_id': carpoolRouteId,
    };

    print('=== Repository: Request body: $body ===');

    final response = await apiClient.postData(AppConstants.startTripUri, body);

    print(
        '=== Repository: Start trip response received with status: ${response.statusCode} ===');
    return response;
  }

  @override
  Future<Response> endTrip(int carpoolRouteId) async {
    print('=== Repository: endTrip called with routeId: $carpoolRouteId ===');
    print('=== Repository: API URL: ${AppConstants.endTripUri} ===');

    final Map<String, dynamic> body = {
      'carpool_route_id': carpoolRouteId,
    };

    print('=== Repository: End trip request body: $body ===');

    final response = await apiClient.postData(AppConstants.endTripUri, body);

    print(
        '=== Repository: End trip response received with status: ${response.statusCode} ===');
    return response;
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
