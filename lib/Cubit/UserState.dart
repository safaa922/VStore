import 'package:virtual_store/Models/UserModel.dart';

abstract class UserState {}

// Initial State
class UserInitial extends UserState {}

// Sign In States
class SignInLoading extends UserState {}

class SignInSuccess extends UserState {
  final String role;

  SignInSuccess({required this.role});
}


class SignInFailure extends UserState {
  final String errorMessage;
  SignInFailure({required this.errorMessage});
}

// Sign Up States
class SignUpLoading extends UserState {}

class SignUpSuccess extends UserState {
  final String message;
  SignUpSuccess({required this.message});
}

class SignUpFailure extends UserState {
  final String errorMessage;
  SignUpFailure({required this.errorMessage});
}

// Profile Picture Upload
class UploadProfilePic extends UserState {}

// User Retrieval States
class GetUserLoading extends UserState {}

class GetUserSuccess extends UserState {
  final UserModel user;
  GetUserSuccess({required this.user});
}

class GetUserFailure extends UserState {
  final String errorMessage;
  GetUserFailure({required this.errorMessage});
}



// Token Verification States
class VerifyTokenLoading extends UserState {}

class VerifyTokenSuccess extends UserState {
  final VerificationResponse verificationResponse;
  VerifyTokenSuccess({required this.verificationResponse});
}

class VerifyTokenFailure extends UserState {
  final String errorMessage;
  VerifyTokenFailure({required this.errorMessage});
}

// Navigation States for Role-Based Redirection
class NavigateToOwnerDashboard extends UserState {}

class NavigateToBuyerDashboard extends UserState {}

// Verification Response Model
class VerificationResponse {
  final bool isVerified;
  final String message;

  VerificationResponse({required this.isVerified, required this.message});

  // Parse JSON response
  factory VerificationResponse.fromJson(Map<String, dynamic> json) {
    return VerificationResponse(
      isVerified: json['isVerified'],
      message: json['message'],
    );
  }
}
