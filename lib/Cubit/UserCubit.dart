import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:virtual_store/Cubit/UserState.dart';
import 'package:virtual_store/Models/LoginModel.dart';
import 'package:virtual_store/Repositories/UserRepository.dart';
import 'package:image_picker/image_picker.dart';

import '../Cache/CasheHelper.dart';
import '../Models/UserModel.dart';

class UserCubit extends Cubit<UserState> {
  UserCubit(this.userRepository) : super(UserInitial());

  final UserRepository userRepository;

  // Form keys
  final GlobalKey<FormState> signInFormKey = GlobalKey();
  final GlobalKey<FormState> signUpFormKey = GlobalKey();

  // Controllers for Sign-In
  final TextEditingController signInEmail = TextEditingController();
  final TextEditingController signInPassword = TextEditingController();

  // Controllers for Sign-Up
  final TextEditingController signUpName = TextEditingController();
  final TextEditingController signUpPhoneNumber = TextEditingController();
  final TextEditingController signUpEmail = TextEditingController();
  final TextEditingController signUpPassword = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();

  // Forgot Password


  // Profile picture
  XFile? profilePic;

  LoginModel? user;

  // Upload Profile Picture
  void uploadProfilePic(XFile image) {
    profilePic = image;
    emit(UploadProfilePic());
  }

  // Sign-Up Method
  Future<void> signUp() async {
    if (profilePic == null) {
      emit(SignUpFailure(errorMessage: 'Profile picture is required.'));
      return;
    }

    emit(SignUpLoading());

    final response = await userRepository.signUp(
      name: signUpName.text,
      phone: signUpPhoneNumber.text,
      email: signUpEmail.text,
      password: signUpPassword.text,
      confirmPassword: confirmPassword.text,
      profilePic: profilePic!,
    );

    response.fold(
          (errorMessage) => emit(SignUpFailure(errorMessage: errorMessage)),
          (signUpModel) => emit(SignUpSuccess(message: signUpModel.message)),
    );
  }

  void signIn() async {
    emit(SignInLoading());

    final result = await userRepository.signIn(
      Email: signInEmail.text,
      Password: signInPassword.text,
    );

    result.fold(
          (error) {
        emit(SignInFailure(errorMessage: error));
      },
          (loginModel) {
        // Save token and role
        CacheHelper().saveToken(loginModel.token ?? "");
        CacheHelper().saveData(key: 'role', value: loginModel.role ?? "");

        // Assign loginModel to the user property
        user = loginModel;

        // Debug log
        print("User logged in: Role: ${loginModel.role ?? 'No role available'}");

        // Emit SignInSuccess with role
        emit(SignInSuccess(role: loginModel.role ?? ""));
      },
    );
  }


  // Fetch User Profile
  Future<void> getUserProfile() async {
    emit(GetUserLoading());

    final response = await userRepository.getUserProfile();

    response.fold(
          (errorMessage) => emit(GetUserFailure(errorMessage: errorMessage)),
          (user) => emit(GetUserSuccess(user: user)),
    );
  }

  // Forgot Password Method

}
