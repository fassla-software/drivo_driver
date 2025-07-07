import 'rest_stop_model.dart';

class RegisterRouteRequestModel {
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String startTime;
  final String rideType;
  final int isAc;
  final int isSmokingAllowed;
  final int seatsAvailable;
  final int hasMusic;
  final String allowedGender;
  final int allowedAgeMin;
  final int allowedAgeMax;
  final int hasScreenEntertainment;
  final int allowLuggage;
  final String vehicleId;
  final double price;
  final List<RestStopModel> restStops;

  RegisterRouteRequestModel({
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.startTime,
    required this.rideType,
    required this.isAc,
    required this.isSmokingAllowed,
    required this.seatsAvailable,
    required this.hasMusic,
    required this.allowedGender,
    required this.allowedAgeMin,
    required this.allowedAgeMax,
    required this.hasScreenEntertainment,
    required this.allowLuggage,
    required this.vehicleId,
    required this.price,
    required this.restStops,
  });

  Map<String, dynamic> toJson() {
    return {
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'start_time': startTime,
      'ride_type': rideType,
      'is_ac': isAc,
      'is_smoking_allowed': isSmokingAllowed,
      'seats_available': seatsAvailable,
      'has_music': hasMusic,
      'allowed_gender': allowedGender,
      'allowed_age_min': allowedAgeMin,
      'allowed_age_max': allowedAgeMax,
      'has_screen_entertainment': hasScreenEntertainment,
      'allow_luggage': allowLuggage,
      'vehicle_id': vehicleId,
      'price': price,
      'rest_stops': restStops.map((stop) => stop.toJson()).toList(),
    };
  }
}
