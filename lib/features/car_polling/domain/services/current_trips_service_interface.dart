abstract class CurrentTripsServiceInterface {
  Future<dynamic> getCurrentTripsWithPassengers();
  Future<dynamic> startTrip(int carpoolRouteId);
}
