import '../repositories/carpool_routes_repository_interface.dart';
import 'carpool_routes_service_interface.dart';

class CarpoolRoutesService implements CarpoolRoutesServiceInterface {
  final CarpoolRoutesRepositoryInterface carpoolRoutesRepositoryInterface;

  CarpoolRoutesService({required this.carpoolRoutesRepositoryInterface});

  @override
  Future getCarpoolRoutes({int offset = 1, int limit = 10}) {
    return carpoolRoutesRepositoryInterface.getCarpoolRoutes(
      offset: offset,
      limit: limit,
    );
  }
}
