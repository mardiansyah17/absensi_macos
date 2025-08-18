import 'package:dio/dio.dart';
import 'package:face_client/core/network/api_interceptor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DioClient {
  final Dio _dio;

  DioClient()
      : _dio = Dio(BaseOptions(
          baseUrl: "http://localhost:8001/api",
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        )) {
    _dio.interceptors.add(
      ApiInterceptor(),
    );

    _dio.interceptors.add(LogInterceptor(
      error: true,
    ));
  }

  Future<Response> get(String path,
      {Map<String, dynamic>? queryParams, options}) async {
    return await _dio.get(path, queryParameters: queryParams);
  }

  // Future<Response> post(String path, {Map<String, dynamic>? data}) async {
  //   return await _dio.post(path, data: data);
  // }
  Future<Response> post(String path, {dynamic data, Options? options}) async {
    return await _dio.post(path, data: data, options: options);
  }

  Future<Response> put(String path, {Map<String, dynamic>? data}) async {
    return await _dio.put(path, data: data);
  }

  Future<Response> delete(String path, {Map<String, dynamic>? data}) async {
    return await _dio.delete(path, data: data);
  }

  Future<Response> patch(String path, {Map<String, dynamic>? data}) async {
    return await _dio.patch(path, data: data);
  }
}
