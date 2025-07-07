class RegisterRouteResponseModel {
  final bool success;
  final String message;
  final String? routeId;
  final Map<String, dynamic>? data;

  RegisterRouteResponseModel({
    required this.success,
    required this.message,
    this.routeId,
    this.data,
  });

  factory RegisterRouteResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterRouteResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      routeId: json['route_id'],
      data: json['data'],
    );
  }
}
