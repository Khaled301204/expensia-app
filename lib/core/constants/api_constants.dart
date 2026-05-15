class ApiConstants {
  // HTTP Methods
  static const String get = 'GET';
  static const String post = 'POST';
  static const String put = 'PUT';
  static const String patch = 'PATCH';
  static const String delete = 'DELETE';
  
  // Headers
  static const String contentType = 'Content-Type';
  static const String authorization = 'Authorization';
  static const String applicationJson = 'application/json';
  static const String multipartFormData = 'multipart/form-data';
  
  // Status Codes
  static const int success = 200;
  static const int created = 201;
  static const int badRequest = 400;
  static const int unauthorized = 401;
  static const int forbidden = 403;
  static const int notFound = 404;
  static const int serverError = 500;
}
