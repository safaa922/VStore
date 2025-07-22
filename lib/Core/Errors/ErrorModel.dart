import 'package:virtual_store/Core/EndPoints.dart';

class ErrorModel {
  final int status;
  final String errorMessage;

  ErrorModel({required this.status, required this.errorMessage});
  factory ErrorModel.fromJson(Map<String, dynamic> jsonData) {
    return ErrorModel(
      status: jsonData[ApiKey.status] ?? 0, // Provide a default value for status
      errorMessage: jsonData[ApiKey.errorMessage] ?? 'An unknown error occurred', // Default value for errorMessage
    );
  }

}