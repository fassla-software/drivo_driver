class PassengerReviewRequestModel {
  final int carpoolPassengerId;
  final String decision; // "accept" or "reject"

  PassengerReviewRequestModel({
    required this.carpoolPassengerId,
    required this.decision,
  });

  Map<String, dynamic> toJson() {
    return {
      'carpool_passenger_id': carpoolPassengerId,
      'decision': decision,
    };
  }
}
