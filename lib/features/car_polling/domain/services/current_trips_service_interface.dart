abstract class CurrentTripsServiceInterface {
  Future<dynamic> getCurrentTripsWithPassengers();
  Future<dynamic> startTrip(int carpoolRouteId);
  Future<dynamic> endTrip(int carpoolRouteId);
}
