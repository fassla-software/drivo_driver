class CurrentTripsWithPassengersResponseModel {
  String? responseCode;
  String? message;
  int? totalSize;
  String? limit;
  String? offset;
  CurrentTripsData? data;
  List<dynamic>? errors;

  CurrentTripsWithPassengersResponseModel({
    this.responseCode,
    this.message,
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
    this.errors,
  });

  factory CurrentTripsWithPassengersResponseModel.fromJson(
      Map<String, dynamic> json) {
    return CurrentTripsWithPassengersResponseModel(
      responseCode: json['response_code'],
      message: json['message'],
      totalSize: json['total_size'],
      limit: json['limit'],
      offset: json['offset'],
      data:
          json['data'] != null ? CurrentTripsData.fromJson(json['data']) : null,
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'response_code': responseCode,
      'message': message,
      'total_size': totalSize,
      'limit': limit,
      'offset': offset,
      'data': data?.toJson(),
      'errors': errors,
    };
  }
}

class CurrentTripsData {
  List<CurrentTrip>? currentTrips;
  int? totalTrips;
  int? upcomingTrips;
  int? ongoingTrips;
  int? completedTrips;

  CurrentTripsData({
    this.currentTrips,
    this.totalTrips,
    this.upcomingTrips,
    this.ongoingTrips,
    this.completedTrips,
  });

  factory CurrentTripsData.fromJson(Map<String, dynamic> json) {
    return CurrentTripsData(
      currentTrips: json['current_trips'] != null
          ? (json['current_trips'] as List)
              .map((item) => CurrentTrip.fromJson(item))
              .toList()
          : null,
      totalTrips: json['total_trips'],
      upcomingTrips: json['upcoming_trips'],
      ongoingTrips: json['ongoing_trips'],
      completedTrips: json['completed_trips'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_trips': currentTrips?.map((item) => item.toJson()).toList(),
      'total_trips': totalTrips,
      'upcoming_trips': upcomingTrips,
      'ongoing_trips': ongoingTrips,
      'completed_trips': completedTrips,
    };
  }
}

class CurrentTrip {
  int? routeId;
  String? tripStatus;
  String? startTime;
  String? endTime;
  String? tripStartedAt;
  String? startAddress;
  String? endAddress;
  TripCoordinates? startCoordinates;
  TripCoordinates? endCoordinates;
  double? price;
  int? seatsAvailable;
  int? totalAcceptedPassengers;
  double? totalFareFromPassengers;
  VehicleInfo? vehicleInfo;
  RoutePreferences? routePreferences;
  List<RestStop>? restStops;
  List<AcceptedPassenger>? acceptedPassengers;

  CurrentTrip({
    this.routeId,
    this.tripStatus,
    this.startTime,
    this.endTime,
    this.tripStartedAt,
    this.startAddress,
    this.endAddress,
    this.startCoordinates,
    this.endCoordinates,
    this.price,
    this.seatsAvailable,
    this.totalAcceptedPassengers,
    this.totalFareFromPassengers,
    this.vehicleInfo,
    this.routePreferences,
    this.restStops,
    this.acceptedPassengers,
  });

  factory CurrentTrip.fromJson(Map<String, dynamic> json) {
    return CurrentTrip(
      routeId: json['route_id'],
      tripStatus: json['trip_status'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      tripStartedAt: json['trip_started_at'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startCoordinates: json['start_coordinates'] != null
          ? TripCoordinates.fromJson(json['start_coordinates'])
          : null,
      endCoordinates: json['end_coordinates'] != null
          ? TripCoordinates.fromJson(json['end_coordinates'])
          : null,
      price: json['price']?.toDouble(),
      seatsAvailable: json['seats_available'],
      totalAcceptedPassengers: json['total_accepted_passengers'],
      totalFareFromPassengers: json['total_fare_from_passengers']?.toDouble(),
      vehicleInfo: json['vehicle_info'] != null
          ? VehicleInfo.fromJson(json['vehicle_info'])
          : null,
      routePreferences: json['route_preferences'] != null
          ? RoutePreferences.fromJson(json['route_preferences'])
          : null,
      restStops: json['rest_stops'] != null
          ? (json['rest_stops'] as List)
              .map((item) => RestStop.fromJson(item))
              .toList()
          : null,
      acceptedPassengers: json['accepted_passengers'] != null
          ? (json['accepted_passengers'] as List)
              .map((item) => AcceptedPassenger.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': routeId,
      'trip_status': tripStatus,
      'start_time': startTime,
      'end_time': endTime,
      'trip_started_at': tripStartedAt,
      'start_address': startAddress,
      'end_address': endAddress,
      'start_coordinates': startCoordinates?.toJson(),
      'end_coordinates': endCoordinates?.toJson(),
      'price': price,
      'seats_available': seatsAvailable,
      'total_accepted_passengers': totalAcceptedPassengers,
      'total_fare_from_passengers': totalFareFromPassengers,
      'vehicle_info': vehicleInfo?.toJson(),
      'route_preferences': routePreferences?.toJson(),
      'rest_stops': restStops?.map((item) => item.toJson()).toList(),
      'accepted_passengers':
          acceptedPassengers?.map((item) => item.toJson()).toList(),
    };
  }
}

class TripCoordinates {
  double? lat;
  double? lng;

  TripCoordinates({this.lat, this.lng});

  factory TripCoordinates.fromJson(Map<String, dynamic> json) {
    return TripCoordinates(
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
    };
  }
}

class VehicleInfo {
  String? brand;
  String? model;
  String? plateNumber;

  VehicleInfo({this.brand, this.model, this.plateNumber});

  factory VehicleInfo.fromJson(Map<String, dynamic> json) {
    return VehicleInfo(
      brand: json['brand'],
      model: json['model'],
      plateNumber: json['plate_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'model': model,
      'plate_number': plateNumber,
    };
  }
}

class RoutePreferences {
  bool? isAc;
  bool? isSmokingAllowed;
  bool? hasMusic;
  bool? hasScreenEntertainment;
  bool? allowLuggage;
  String? allowedGender;
  int? allowedAgeMin;
  int? allowedAgeMax;

  RoutePreferences({
    this.isAc,
    this.isSmokingAllowed,
    this.hasMusic,
    this.hasScreenEntertainment,
    this.allowLuggage,
    this.allowedGender,
    this.allowedAgeMin,
    this.allowedAgeMax,
  });

  factory RoutePreferences.fromJson(Map<String, dynamic> json) {
    return RoutePreferences(
      isAc: json['is_ac'],
      isSmokingAllowed: json['is_smoking_allowed'],
      hasMusic: json['has_music'],
      hasScreenEntertainment: json['has_screen_entertainment'],
      allowLuggage: json['allow_luggage'],
      allowedGender: json['allowed_gender'],
      allowedAgeMin: json['allowed_age_min'],
      allowedAgeMax: json['allowed_age_max'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_ac': isAc,
      'is_smoking_allowed': isSmokingAllowed,
      'has_music': hasMusic,
      'has_screen_entertainment': hasScreenEntertainment,
      'allow_luggage': allowLuggage,
      'allowed_gender': allowedGender,
      'allowed_age_min': allowedAgeMin,
      'allowed_age_max': allowedAgeMax,
    };
  }
}

class RestStop {
  double? lat;
  double? lng;
  String? name;

  RestStop({this.lat, this.lng, this.name});

  factory RestStop.fromJson(Map<String, dynamic> json) {
    return RestStop(
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
      name: json['name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
    };
  }
}

class AcceptedPassenger {
  int? passengerId;
  String? passengerName;
  String? passengerPhone;
  String? profileImage;
  int? seatsCount;
  double? fare;
  String? status;
  String? pickupAddress;
  String? dropoffAddress;
  TripCoordinates? pickupCoordinates;
  TripCoordinates? dropoffCoordinates;
  String? otp;
  String? arrivedAt;
  String? leftAt;

  AcceptedPassenger({
    this.passengerId,
    this.passengerName,
    this.passengerPhone,
    this.profileImage,
    this.seatsCount,
    this.fare,
    this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.otp,
    this.arrivedAt,
    this.leftAt,
  });

  factory AcceptedPassenger.fromJson(Map<String, dynamic> json) {
    return AcceptedPassenger(
      passengerId: json['passenger_id'],
      passengerName: json['passenger_name'],
      passengerPhone: json['passenger_phone'],
      profileImage: json['profile_image'],
      seatsCount: json['seats_count'],
      fare: json['fare']?.toDouble(),
      status: json['status'],
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      pickupCoordinates: json['pickup_coordinates'] != null
          ? TripCoordinates.fromJson(json['pickup_coordinates'])
          : null,
      dropoffCoordinates: json['dropoff_coordinates'] != null
          ? TripCoordinates.fromJson(json['dropoff_coordinates'])
          : null,
      otp: json['otp'],
      arrivedAt: json['arrived_at'],
      leftAt: json['left_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'passenger_id': passengerId,
      'passenger_name': passengerName,
      'passenger_phone': passengerPhone,
      'profile_image': profileImage,
      'seats_count': seatsCount,
      'fare': fare,
      'status': status,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_coordinates': pickupCoordinates?.toJson(),
      'dropoff_coordinates': dropoffCoordinates?.toJson(),
      'otp': otp,
      'arrived_at': arrivedAt,
      'left_at': leftAt,
    };
  }
}
