
import 'package:virtual_store/Models/ForgotPasswordModel.dart';

abstract class ForgotPasswordState {}

class ForgotPasswordInitial extends ForgotPasswordState {}

class ForgotPasswordLoading extends ForgotPasswordState {}

class ForgotPasswordSuccess extends ForgotPasswordState {
  final String token; // Token for password reset
  ForgotPasswordSuccess({required this.token});
}

class ForgotPasswordFailure extends ForgotPasswordState {
  final String errorMessage;
  ForgotPasswordFailure({required this.errorMessage});

}