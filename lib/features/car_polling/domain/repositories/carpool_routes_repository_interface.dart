import 'package:get/get_connect/http/src/response/response.dart';
import '../../../../interface/repository_interface.dart';

abstract class CarpoolRoutesRepositoryInterface implements RepositoryInterface {
  Future<Response> getCarpoolRoutes({int offset = 1, int limit = 10});
}
