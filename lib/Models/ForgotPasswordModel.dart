import 'package:virtual_store/Core/EndPoints.dart';
import 'package:virtual_store/screens/ForgotPassword.dart';

class ForgotPasswordModel {
  final String message;
  final String token;

  ForgotPasswordModel({required this.message, required this.token});

  factory ForgotPasswordModel.fromJson(Map<String, dynamic> jsonData) {
    return ForgotPasswordModel(
      message: jsonData[ApiKey.message],
      token: jsonData[ApiKey.token]['token'], // Access nested token value
    );
  }
}
