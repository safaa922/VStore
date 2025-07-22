import 'package:virtual_store/Core/EndPoints.dart';

class LoginModel {
  final String message;
  final String token;
  final String role;  // Changed from isOwner to role

  LoginModel({
    required this.message,
    required this.token,
    required this.role,  // Set role directly
  });

  factory LoginModel.fromJson(Map<String, dynamic> jsonData) {
    return LoginModel(
      message: jsonData['message'],
      token: jsonData['token']['token'],  // Adjust if needed
      role: jsonData['role'],  // Directly assign the role
    );
  }
}





