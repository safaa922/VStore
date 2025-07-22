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

class UserRepository {
  final ApiConsumer api;

  UserRepository({required this.api});

  // SignIn method
  Future<Either<String, LoginModel>> signIn({
    required String Email,
    required String Password,
  }) async {
    try {
      final formData = FormData.fromMap({
        "Email": Email,
        "Password": Password,
      });

      final response = await api.post(
        EndPoint.signIn,
        data: formData,
      );

      if (response is Map<String, dynamic>) {
        final user = LoginModel.fromJson(response);

        final decodedToken = JwtDecoder.decode(user.token);
        // Store the token and user ID in shared preferences
        CacheHelper().saveData(key: ApiKey.token, value: user.token);
        CacheHelper().saveData(key: ApiKey.id, value: decodedToken[ApiKey.id]);

        return Right(user);
      } else {
        return Left('Error: Unexpected response format');
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

  // Verify Token Method (checking the token from cache)
  Future<Either<String, UserModel>> verifyTokenLocally({
    required String token,
  }) async {
    try {
      String? storedToken = CacheHelper().getDataString(key: ApiKey.token);

      if (storedToken == null || storedToken != token) {
        return Left('Token mismatch or token not found');
      }

      // If tokens match, decode and fetch the user details
      final decodedToken = JwtDecoder.decode(storedToken);
      final response = await api.get(
        EndPoint.getUserDataEndPoint(decodedToken[ApiKey.id]),
      );

      if (response is Map<String, dynamic>) {
        final userModel = UserModel.fromJson(response);
        return Right(userModel);
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

  // Token verification via API




// SignUp method
  Future<Either<String, SignUpModel>> signUp({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String confirmPassword,
    required XFile profilePic,
  }) async {
    try {
      final response = await api.post(
        EndPoint.signUp,
        isFromData: true,
        data: {
          ApiKey.name: name,
          ApiKey.phone: phone,
          ApiKey.Email: email,
          ApiKey.Password: password,
          ApiKey.confirmPassword: confirmPassword,
          ApiKey.location:
          '{"name":"methalfa","address":"meet halfa","coordinates":[30.1572709,31.224779]}',
          ApiKey.profilePic: await uploadImageToAPI(profilePic),
        },
      );
      final signUPModel = SignUpModel.fromJson(response);
      return Right(signUPModel);
    } on ServerException catch (e) {
      return Left(e.errModel.errorMessage);
    }
  }

  // Get User Profile method
  Future<Either<String, UserModel>> getUserProfile() async {
    try {
      final response = await api.get(
        EndPoint.getUserDataEndPoint(
          CacheHelper().getData(key: ApiKey.id),
        ),
      );

      if (response is Map<String, dynamic>) {
        final userProfile = UserModel.fromJson(response);
        return Right(userProfile);
      } else {
        return Left('Unexpected response format');
      }
    } on ServerException catch (e) {
      return Left(e.errModel.errorMessage);
    }
  }
}


