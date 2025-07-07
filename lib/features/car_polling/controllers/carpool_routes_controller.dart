import 'package:get/get.dart';
import '../../../data/api_checker.dart';
import '../domain/models/carpool_routes_response_model.dart';
import '../domain/services/carpool_routes_service_interface.dart';

class CarpoolRoutesController extends GetxController implements GetxService {
  final CarpoolRoutesServiceInterface carpoolRoutesServiceInterface;

  CarpoolRoutesController({required this.carpoolRoutesServiceInterface});

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  CarpoolRoutesResponseModel? _carpoolRoutesResponse;
  CarpoolRoutesResponseModel? get carpoolRoutesResponse =>
      _carpoolRoutesResponse;

  List<CarpoolRoute> _carpoolRoutes = [];
  List<CarpoolRoute> get carpoolRoutes => _carpoolRoutes;

  int _currentPage = 1;
  int get currentPage => _currentPage;

  bool _hasMoreData = true;
  bool get hasMoreData => _hasMoreData;

  final int _limit = 10;
  int get limit => _limit;

  @override
  void onInit() {
    super.onInit();
    getCarpoolRoutes();
  }

  /// Get carpool routes from API
  Future<void> getCarpoolRoutes({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _carpoolRoutes.clear();
    }

    _isLoading = isRefresh || _currentPage == 1;
    _isLoadingMore = !isRefresh && _currentPage > 1;
    update();

    try {
      Response response = await carpoolRoutesServiceInterface.getCarpoolRoutes(
        offset: _currentPage,
        limit: _limit,
      );

      if (response.statusCode == 200) {
        _carpoolRoutesResponse =
            CarpoolRoutesResponseModel.fromJson(response.body);

        if (_carpoolRoutesResponse?.data != null) {
          if (isRefresh || _currentPage == 1) {
            _carpoolRoutes = _carpoolRoutesResponse!.data!;
          } else {
            _carpoolRoutes.addAll(_carpoolRoutesResponse!.data!);
          }

          // Check if there's more data
          if (_carpoolRoutesResponse!.data!.length < _limit) {
            _hasMoreData = false;
          }
        } else {
          _hasMoreData = false;
        }

        _isLoading = false;
        _isLoadingMore = false;
        update();
      } else {
        _isLoading = false;
        _isLoadingMore = false;
        update();
        ApiChecker.checkApi(response);
      }
    } catch (e) {
      _isLoading = false;
      _isLoadingMore = false;
      update();
      Get.showSnackbar(GetSnackBar(
        title: 'error'.tr,
        message: 'failed_to_load_carpool_routes'.tr,
        duration: const Duration(seconds: 3),
        backgroundColor: Get.theme.colorScheme.error,
      ));
    }
  }

  /// Load more carpool routes (pagination)
  Future<void> loadMoreCarpoolRoutes() async {
    if (_isLoadingMore || !_hasMoreData) return;

    _currentPage++;
    await getCarpoolRoutes();
  }

  /// Refresh carpool routes
  Future<void> refreshCarpoolRoutes() async {
    await getCarpoolRoutes(isRefresh: true);
  }

  /// Get route by index
  CarpoolRoute? getRouteAt(int index) {
    if (index >= 0 && index < _carpoolRoutes.length) {
      return _carpoolRoutes[index];
    }
    return null;
  }

  /// Get total routes count
  int get totalRoutesCount => _carpoolRoutes.length;

  /// Check if route has passengers
  bool routeHasPassengers(CarpoolRoute route) {
    return route.passengersCount != null && route.passengersCount! > 0;
  }

  /// Get available seats for a route
  int getAvailableSeats(CarpoolRoute route) {
    int totalSeats = route.seats ?? 0;
    int occupiedSeats = route.passengersCount ?? 0;
    return totalSeats - occupiedSeats;
  }

  /// Get route features as a list of strings
  List<String> getRouteFeatures(CarpoolRoute route) {
    List<String> features = [];

    if (route.isAc == true) features.add('AC');
    if (route.hasMusic == true) features.add('Music');
    if (route.hasScreenEntertainment == true) features.add('Entertainment');
    if (route.allowLuggage == true) features.add('Luggage');
    if (route.isSmokingAllowed == true) features.add('Smoking');

    return features;
  }

  /// Clear all data
  void clearData() {
    _carpoolRoutes.clear();
    _carpoolRoutesResponse = null;
    _currentPage = 1;
    _hasMoreData = true;
    _isLoading = false;
    _isLoadingMore = false;
    update();
  }
}
