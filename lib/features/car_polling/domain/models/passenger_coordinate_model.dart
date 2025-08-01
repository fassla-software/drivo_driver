class PassengerCoordinateModel {
  String? type; // pickup or dropoff
  String? passengerId;
  List<double>? pickupCoordinates;
  List<double>? dropoffCoordinates;
  String? address;

  PassengerCoordinateModel({
    this.type,
    this.passengerId,
    this.pickupCoordinates,
    this.dropoffCoordinates,
    this.address,
  });

  factory PassengerCoordinateModel.fromJson(Map<String, dynamic> json) {
    print('=== PassengerCoordinateModel.fromJson: $json ===');

    final model = PassengerCoordinateModel(
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

    print(
        '=== Created model: type=${model.type}, coords=${model.coordinates} ===');
    return model;
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

  // Helper methods
  List<double>? get coordinates {
    print('=== Getting coordinates for type: $type ===');
    print('=== Pickup coordinates: $pickupCoordinates ===');
    print('=== Dropoff coordinates: $dropoffCoordinates ===');

    if (type == 'pickup') {
      return pickupCoordinates;
    } else if (type == 'dropoff') {
      return dropoffCoordinates;
    }
    return null;
  }

  bool get hasValidCoordinates {
    if (type == 'pickup') {
      return pickupCoordinates != null && pickupCoordinates!.length >= 2;
    } else if (type == 'dropoff') {
      return dropoffCoordinates != null && dropoffCoordinates!.length >= 2;
    }
    return false;
  }

  bool get isPickup => type == 'pickup';
  bool get isDropoff => type == 'dropoff';
}
