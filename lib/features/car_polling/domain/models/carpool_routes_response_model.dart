class CarpoolRoutesResponseModel {
  String? responseCode;
  String? message;
  int? totalSize;
  String? limit;
  String? offset;
  List<CarpoolRoute>? data;
  List<dynamic>? errors;

  CarpoolRoutesResponseModel({
    this.responseCode,
    this.message,
    this.totalSize,
    this.limit,
    this.offset,
    this.data,
    this.errors,
  });

  factory CarpoolRoutesResponseModel.fromJson(Map<String, dynamic> json) {
    return CarpoolRoutesResponseModel(
      responseCode: json['response_code'],
      message: json['message'],
      totalSize: json['total_size'],
      limit: json['limit'],
      offset: json['offset'],
      data: json['data'] != null
          ? (json['data'] as List)
              .map((item) => CarpoolRoute.fromJson(item))
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

class CarpoolRoute {
  String? name;
  String? profileImage;
  int? seats;
  bool? isSmokingAllowed;
  bool? isAc;
  String? allowedGender;
  int? allowedAgeMin;
  int? allowedAgeMax;
  bool? hasScreenEntertainment;
  bool? hasMusic;
  bool? allowLuggage;
  String? startDay;
  String? startHour;
  String? startAddress;
  String? endAddress;
  String? vehicleName;
  int? passengersCount;
  List<Passenger>? passengers;

  CarpoolRoute({
    this.name,
    this.profileImage,
    this.seats,
    this.isSmokingAllowed,
    this.isAc,
    this.allowedGender,
    this.allowedAgeMin,
    this.allowedAgeMax,
    this.hasScreenEntertainment,
    this.hasMusic,
    this.allowLuggage,
    this.startDay,
    this.startHour,
    this.startAddress,
    this.endAddress,
    this.vehicleName,
    this.passengersCount,
    this.passengers,
  });

  factory CarpoolRoute.fromJson(Map<String, dynamic> json) {
    return CarpoolRoute(
      name: json['name'],
      profileImage: json['profile_image'],
      seats: json['seats'],
      isSmokingAllowed: json['is_smoking_allowed'],
      isAc: json['is_ac'],
      allowedGender: json['allowed_gender'],
      allowedAgeMin: json['allowed_age_min'],
      allowedAgeMax: json['allowed_age_max'],
      hasScreenEntertainment: json['has_screen_entertainment'],
      hasMusic: json['has_music'],
      allowLuggage: json['allow_luggage'],
      startDay: json['start_day'],
      startHour: json['start_hour'],
      startAddress: json['start_address'],
      endAddress: json['end_address'],
      vehicleName: json['vehicle_name'],
      passengersCount: json['passengers_count'],
      passengers: json['passengers'] != null
          ? (json['passengers'] as List)
              .map((item) => Passenger.fromJson(item))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'profile_image': profileImage,
      'seats': seats,
      'is_smoking_allowed': isSmokingAllowed,
      'is_ac': isAc,
      'allowed_gender': allowedGender,
      'allowed_age_min': allowedAgeMin,
      'allowed_age_max': allowedAgeMax,
      'has_screen_entertainment': hasScreenEntertainment,
      'has_music': hasMusic,
      'allow_luggage': allowLuggage,
      'start_day': startDay,
      'start_hour': startHour,
      'start_address': startAddress,
      'end_address': endAddress,
      'vehicle_name': vehicleName,
      'passengers_count': passengersCount,
      'passengers': passengers?.map((item) => item.toJson()).toList(),
    };
  }
}

class Passenger {
  int? carpoolPassengerId;
  String? name;
  String? pickupAddress;
  String? dropoffAddress;
  int? seatsCount;
  double? fare;
  String? profileImage;

  Passenger({
    this.carpoolPassengerId,
    this.name,
    this.pickupAddress,
    this.dropoffAddress,
    this.seatsCount,
    this.fare,
    this.profileImage,
  });

  factory Passenger.fromJson(Map<String, dynamic> json) {
    return Passenger(
      carpoolPassengerId: json['carpool_passenger_id'],
      name: json['name'],
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      seatsCount: json['seats_count'],
      fare: json['fare']?.toDouble(),
      profileImage: json['profile_image'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'carpool_passenger_id': carpoolPassengerId,
      'name': name,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'seats_count': seatsCount,
      'fare': fare,
      'profile_image': profileImage,
    };
  }
}
