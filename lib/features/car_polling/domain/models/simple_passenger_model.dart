import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SimplePassengerModel {
  int? id;
  String? name;
  String? profileImage;
  int? seatsCount;
  double? fare;
  String? status;
  String? pickupAddress;
  String? dropoffAddress;
  List<double>? pickupCoordinates;
  List<double>? dropoffCoordinates;
  String? phone;
  String? email;
  String? carpoolTripId;

  SimplePassengerModel({
    this.id,
    this.name,
    this.profileImage,
    this.seatsCount,
    this.fare,
    this.status,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.phone,
    this.email,
    this.carpoolTripId,
  });

  factory SimplePassengerModel.fromJson(Map<String, dynamic> json) {
    print('=== SimplePassengerModel.fromJson: $json ===');
    return SimplePassengerModel(
      id: json['id'],
      name: json['name'],
      profileImage: json['profile_image'],
      seatsCount: json['seats_count'],
      fare: json['fare']?.toDouble(),
      status: json['status'],
      pickupAddress: json['pickup_address'],
      dropoffAddress: json['dropoff_address'],
      pickupCoordinates: json['pickup_coordinates'] != null
          ? List<double>.from(json['pickup_coordinates'])
          : null,
      dropoffCoordinates: json['dropoff_coordinates'] != null
          ? List<double>.from(json['dropoff_coordinates'])
          : null,
      phone: json['phone'],
      email: json['email'],
      carpoolTripId: json['carpool_trip_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profile_image': profileImage,
      'seats_count': seatsCount,
      'fare': fare,
      'status': status,
      'pickup_address': pickupAddress,
      'dropoff_address': dropoffAddress,
      'pickup_coordinates': pickupCoordinates,
      'dropoff_coordinates': dropoffCoordinates,
      'phone': phone,
      'email': email,
      'carpool_trip_id': carpoolTripId,
    };
  }

  // Helper methods
  String get formattedFare {
    return '${fare?.toStringAsFixed(2) ?? '0'} EGP';
  }

  String get statusDisplayText {
    switch (status?.toLowerCase()) {
      case 'pending':
        return 'pending'.tr;
      case 'accepted':
        return 'accepted'.tr;
      case 'picked_up':
        return 'picked_up'.tr;
      case 'dropped_off':
        return 'dropped_off'.tr;
      case 'cancelled':
        return 'cancelled'.tr;
      default:
        return 'unknown'.tr;
    }
  }

  Color get statusColor {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'picked_up':
        return Colors.blue;
      case 'dropped_off':
        return Colors.purple;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
