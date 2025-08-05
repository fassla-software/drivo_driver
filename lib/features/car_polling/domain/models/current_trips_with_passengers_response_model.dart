import '../models/carpool_routes_response_model.dart';

class CurrentTripsWithPassengersResponseModel {
  String? responseCode;
  String? message;
  int? totalSize;
  String? limit;
  String? offset;
  List<CurrentTrip>? data;
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
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => CurrentTrip.fromJson(item))
              .toList()
          : null,
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
      'data': data?.map((item) => item.toJson()).toList(),
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

class PassengerCoordinate {
  String? type;
  String? passengerId;
  List<double>? pickupCoordinates;
  List<double>? dropoffCoordinates;
  String? address;

  PassengerCoordinate({
    this.type,
    this.passengerId,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.address,
  });

  factory PassengerCoordinate.fromJson(Map<String, dynamic> json) {
    return PassengerCoordinate(
      type: json['type'],
      passengerId: json['passenger_id'],
      pickupCoordinates: json['pickup_coordinates'] != null
          ? List<double>.from(json['pickup_coordinates'])
          : null,
      dropoffCoordinates: json['dropoff_coordinates'] != null
          ? List<double>.from(json['dropoff_coordinates'])
          : null,
      address: json['address'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'passenger_id': passengerId,
      'pickup_coordinates': pickupCoordinates,
      'dropoff_coordinates': dropoffCoordinates,
      'address': address,
    };
  }
}

class CurrentTrip {
  int? routeId;
  String? tripStatus;
  String? startTime;
  String? endTime;
  String? tripStartedAt;
  int? isTripStarted;
  String? startAddress;
  String? endAddress;
  List<double>? startCoordinates; // <-- تحديث هنا
  List<double>? endCoordinates; // <-- تحديث هنا
  double? price;
  int? seatsAvailable;
  int? totalAcceptedPassengers;
  double? totalFareFromPassengers;
  VehicleInfo? vehicleInfo;
  RoutePreferences? routePreferences;
  List<RestStop>? restStops;
  List<AcceptedPassenger>? acceptedPassengers;
  List<Passenger>? pendingPassengers;

  CurrentTrip({
    this.routeId,
    this.tripStatus,
    this.startTime,
    this.endTime,
    this.tripStartedAt,
    this.isTripStarted,
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
    this.pendingPassengers,
  });

  factory CurrentTrip.fromJson(Map<String, dynamic> json) {
    return CurrentTrip(
      routeId: json['route_id'] ?? json['id'],
      tripStatus: json['trip_status'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      tripStartedAt: json['trip_started_at'],
      isTripStarted: json.containsKey('is_trip_started')
          ? (json['is_trip_started'] is int
              ? json['is_trip_started']
              : int.tryParse(json['is_trip_started']?.toString() ?? '0'))
          : 0,
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      startCoordinates: json['start_coordinates'] != null
          ? List<double>.from(
              json['start_coordinates'].map((x) => x.toDouble()))
          : null,
      endCoordinates: json['end_coordinates'] != null
          ? List<double>.from(json['end_coordinates'].map((x) => x.toDouble()))
          : null,
      price: json['price']?.toDouble(),
      seatsAvailable:
          json['available_seats'] ?? json['seats_available'] ?? json['seats'],
      totalAcceptedPassengers:
          json['total_accepted_passengers'] ?? json['passengers_count'],
      totalFareFromPassengers: json['total_fare_from_passengers']?.toDouble(),
      vehicleInfo: json['vehicle_info'] != null
          ? VehicleInfo.fromJson(json['vehicle_info'])
          : (json['vehicle_name'] != null
              ? VehicleInfo(brand: json['vehicle_name'])
              : null),
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
      pendingPassengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((item) => Passenger.fromJson(item))
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
      'is_trip_started': isTripStarted,
      'start_address': startAddress,
      'end_address': endAddress,
      'start_coordinates': startCoordinates,
      'end_coordinates': endCoordinates,
      'price': price,
      'seats_available': seatsAvailable,
      'total_accepted_passengers': totalAcceptedPassengers,
      'total_fare_from_passengers': totalFareFromPassengers,
      'vehicle_info': vehicleInfo?.toJson(),
      'route_preferences': routePreferences?.toJson(),
      'rest_stops': restStops?.map((item) => item.toJson()).toList(),
      'accepted_passengers':
          acceptedPassengers?.map((item) => item.toJson()).toList(),
      'passengers': pendingPassengers?.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods for backward compatibility
  int get id => routeId ?? 0;
  int get totalAcceptedPassengersCount => totalAcceptedPassengers ?? 0;
  double get totalFareFromPassengersAmount => totalFareFromPassengers ?? 0.0;
  int get seatsAvailableCount => seatsAvailable ?? 0;
  List<AcceptedPassenger>? get passengers => acceptedPassengers;
  List<Passenger>? get pendingPassengersList => pendingPassengers;
  String? get vehicleName => vehicleInfo?.model != null
      ? '${vehicleInfo!.brand}-${vehicleInfo!.model}'
      : vehicleInfo?.brand;

  // Helper for price
  double? get priceAmount => price;
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
  String? carpoolTripId;
  String? name;
  String? pickupAddress;
  int? seatsCount;
  List<double>? startCoordinates;
  List<double>? endCoordinates;
  double? price;
  String? status;
  String? profileImage;

  AcceptedPassenger({
    this.carpoolTripId,
    this.name,
    this.pickupAddress,
    this.seatsCount,
    this.startCoordinates,
    this.endCoordinates,
    this.price,
    this.status,
    this.profileImage,
  });

  factory AcceptedPassenger.fromJson(Map<String, dynamic> json) {
    return AcceptedPassenger(
      carpoolTripId: json['carpool_trip_id'],
      name: json['name'],
      pickupAddress: json['pickup_address'],
      seatsCount: json['seats_count'],
      startCoordinates: json['start_coordinates'] != null
          ? List<double>.from(json['start_coordinates'])
          : null,
      endCoordinates: json['end_coordinates'] != null
          ? List<double>.from(json['end_coordinates'])
          : null,
      price: json['price']?.toDouble(),
      status: json['status'],
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carpool_trip_id': carpoolTripId,
      'name': name,
      'pickup_address': pickupAddress,
      'seats_count': seatsCount,
      'start_coordinates': startCoordinates,
      'end_coordinates': endCoordinates,
      'price': price,
      'status': status,
      'profile_image': profileImage,
    };
  }

  // Helper getters for backward compatibility
  int? get passengerId => null;
  String? get passengerName => name;
  String? get passengerPhone => null;
  String? get dropoffAddress => null;
  TripCoordinates? get pickupCoordinates {
    if (startCoordinates != null && startCoordinates!.length >= 2) {
      return TripCoordinates(
        lat: startCoordinates![1], // longitude is first in API response
        lng: startCoordinates![0], // latitude is second in API response
      );
    }
    return null;
  }

  TripCoordinates? get dropoffCoordinates {
    if (endCoordinates != null && endCoordinates!.length >= 2) {
      return TripCoordinates(
        lat: endCoordinates![1], // longitude is first in API response
        lng: endCoordinates![0], // latitude is second in API response
      );
    }
    return null;
  }

  String? get otp => null;
  String? get arrivedAt => null;
  String? get leftAt => null;
  double? get fare => price;
  double? get estimatedFare => price;
  double? get actualFare => price;
}
