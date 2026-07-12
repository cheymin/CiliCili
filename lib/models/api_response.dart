class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  bool get isSuccess => code == 0;

  ApiResponse({required this.code, required this.message, this.data});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T? Function(dynamic) dataParser,
  ) {
    return ApiResponse(
      code: json['code'] as int? ?? -1,
      message: json['message'] as String? ?? '',
      data: json['data'] != null ? dataParser(json['data']) : null,
    );
  }
}
