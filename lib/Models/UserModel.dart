import 'package:virtual_store/Core/EndPoints.dart';
import 'package:virtual_store/Repositories/UserRepository.dart'; // Import your repository for the token verification

class UserModel {
  final String profilePic;
  final String email;
  final String phone;
  final String name;
  final Map<String, dynamic> address;
  final String token;

  UserModel({
    required this.profilePic,
    required this.email,
    required this.phone,
    required this.name,
    required this.address,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> jsonData) {
    return UserModel(
      profilePic: jsonData['user'][ApiKey.profilePic] ?? '',
      email: jsonData['user'][ApiKey.Email] ?? '',
      phone: jsonData['user'][ApiKey.phone] ?? '',
      name: jsonData['user'][ApiKey.name] ?? '',
      address: jsonData['user'][ApiKey.location] ?? {},
      token: jsonData['token'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'profilePic': profilePic,
      'email': email,
      'phone': phone,
      'name': name,
      'address': address,
      'token': token,
    };
  }
}


