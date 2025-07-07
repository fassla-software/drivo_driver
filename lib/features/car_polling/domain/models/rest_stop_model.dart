class RestStopModel {
  final double lat;
  final double lng;
  final String name;

  RestStopModel({
    required this.lat,
    required this.lng,
    required this.name,
  });

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
    };
  }

  factory RestStopModel.fromJson(Map<String, dynamic> json) {
    return RestStopModel(
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      name: json['name'] ?? '',
    );
  }
}
