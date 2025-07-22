import 'package:dio/dio.dart';
import 'package:virtual_store/Cache/CasheHelper.dart';
import 'package:virtual_store/Core/EndPoints.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers[ApiKey.token] =
    CacheHelper().getData(key: ApiKey.token) != null
        ? 'FOODAPI ${CacheHelper().getData(key: ApiKey.token)}'
        : null;
    super.onRequest(options, handler);
  }
}