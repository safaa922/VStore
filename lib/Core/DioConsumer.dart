import 'package:dio/dio.dart';
import 'package:virtual_store/Core/ApiConsumer.dart';
import 'package:virtual_store/Core/Api_Interceptors.dart';
import 'package:virtual_store/Core/EndPoints.dart';
import 'package:virtual_store/Core/Errors/Exceptions.dart';

class DioConsumer extends ApiConsumer {
  final Dio dio;

  DioConsumer({required this.dio}) {
    dio.options.baseUrl = EndPoint.baseUrl;
    dio.interceptors.add(ApiInterceptor());
    dio.interceptors.add(LogInterceptor(
      request: true,
      requestHeader: true,
      requestBody: true,
      responseHeader: true,
      responseBody: true,
      error: true,
    ));
  }

  @override
  Future delete(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        bool isFromData = false,
      }) async {
    try {
      final response = await dio.delete(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future get(String path,
      {Object? data, Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await dio.get(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future patch(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        bool isFromData = false,
      }) async {
    try {
      final response = await dio.patch(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }

  @override
  Future post(
      String path, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        bool isFromData = false,
        Options? options, // Allow custom options
      }) async {
    try {
      final response = await dio.post(
        path,
        data: isFromData ? FormData.fromMap(data) : data,
        queryParameters: queryParameters,
        options: options ?? Options(headers: {}), // Provide default options if none are passed
      );
      return response.data;
    } on DioException catch (e) {
      handleDioExceptions(e);
    }
  }


}