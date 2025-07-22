import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:virtual_store/Cache/CasheHelper.dart';
import 'package:virtual_store/Core/ApiConsumer.dart';
import 'package:virtual_store/Core/EndPoints.dart';
import 'package:virtual_store/Core/Errors/Exceptions.dart';
import 'package:virtual_store/Core/Functions/Upload_Image_ToApi.dart';
import 'package:virtual_store/Models/LoginModel.dart';
import 'package:virtual_store/Models/SignUpModel.dart';
import 'package:virtual_store/Models/UserModel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:virtual_store/Cubit/UserState.dart';


class ForgotPasswordRepository {
  final ApiConsumer api;

  //Forgotpasswordrepository({required this.api});

  ForgotPasswordRepository({required this.api});


  Future<Either<String, String>> forgotPassword({required String email}) async {
    try {
      // Create the form data
      var formData = FormData.fromMap({
        'Email': email,
      });

      // Send the request with multipart/form-data content type automatically handled by Dio
      final response = await api.post(
        EndPoint.ForgotPassword,
        data: formData,
      );

      // Handle response
      if (response is Map<String, dynamic>) {
        final token = response['token']; // Adjust based on your API response
        return Right(token);
      } else {
        return Left('Unexpected response format');
      }
    } on DioError catch (e) {
      if (e.response != null && e.response?.data != null) {
        return Left(e.response?.data['ErrorMessage'] ?? 'An error occurred.');
      }
      return Left('Network error: ${e.message}');
    } catch (e) {
      return Left('Unexpected error: $e');
    }
  }
}


