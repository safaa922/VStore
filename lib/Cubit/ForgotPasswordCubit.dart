
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:virtual_store/Cubit/ForgotPasswordState.dart';
import 'package:virtual_store/Models/LoginModel.dart';
import 'package:virtual_store/Repositories/ForgotPasswordRepository.dart';


class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPasswordRepository forgotPasswordRepository; // Corrected this line

  ForgotPasswordCubit(this.forgotPasswordRepository) : super(ForgotPasswordInitial()); // Pass the repository here
  final TextEditingController forgotPasswordEmail = TextEditingController();

  Future<void> forgotPassword() async {
    if (forgotPasswordEmail.text.isEmpty) {
      emit(ForgotPasswordFailure(errorMessage: 'Please enter your email.'));
      return;
    }

    // Validate email format
    final emailRegex = RegExp(
        r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");
    if (!emailRegex.hasMatch(forgotPasswordEmail.text)) {
      emit(ForgotPasswordFailure(errorMessage: 'Please enter a valid email.'));
      return;
    }

    emit(ForgotPasswordLoading());

    final response = await forgotPasswordRepository.forgotPassword(
        email: forgotPasswordEmail.text); // Use the corrected repository name

    response.fold(
          (errorMessage) =>
          emit(ForgotPasswordFailure(errorMessage: errorMessage)),
          (token) => emit(ForgotPasswordSuccess(token: token)),
    );
  }
}