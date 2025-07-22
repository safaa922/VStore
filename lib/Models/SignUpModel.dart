import 'package:virtual_store/Core/EndPoints.dart';


class SignUpModel {
  final String message;

  SignUpModel({required this.message});
  factory SignUpModel.fromJson(Map<String, dynamic> jsonData) {
    return SignUpModel(message: jsonData[ApiKey.message]);
  }
}