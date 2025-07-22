
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:virtual_store/screens/UserProfile.dart';

class EditUserProfile extends StatefulWidget {
  final UserProfileModel userProfile;

  EditUserProfile({required this.userProfile});

  @override
  _EditUserProfileState createState() => _EditUserProfileState();
}

class _EditUserProfileState extends State<EditUserProfile> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _addListeners();
  }

  void _initializeControllers() {
    _firstNameController.text = widget.userProfile.fName ?? '';
    _lastNameController.text = widget.userProfile.lName ?? '';
    _userNameController.text = widget.userProfile.userName ?? '';
    _emailController.text = widget.userProfile.email ?? '';
    _locationController.text = widget.userProfile.address ?? '';
    _phoneController.text = widget.userProfile.phoneNumber ?? '';
  }

  void _addListeners() {
    _firstNameController.addListener(_updateFormState);
    _lastNameController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);
    _userNameController.addListener(_updateFormState);
    _locationController.addListener(_updateFormState);
    _phoneController.addListener(_updateFormState);
  }

  void _updateFormState() {
    final isFormValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _userNameController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty;
    _isFormValid.value = isFormValid;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        final base64Image = base64Encode(bytes);

        setState(() {
          widget.userProfile.imageBase64 = base64Image;
        });

        await _updateProfilePhoto(base64Image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _updateProfilePhoto(String base64Image) async {
    final url = Uri.parse('http://vstore.runasp.net/api/User/Update_photo/${widget.userProfile.id}');

    final Map<String, String> requestBody = {
      'Image': base64Image,
    };

    try {
      final response = await http.put(
        url,
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photo updated successfully')),
        );
      } else {
        throw Exception('Failed to update profile photo: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile photo: $e')),
      );
    }
  }

  Future<void> _updateUserProfile() async {
    _isLoading.value = true;

    final url = Uri.parse('http://vstore.runasp.net/api/User/Update_User/${widget.userProfile.id}');

    final Map<String, String> requestBody = {
      'FName': _firstNameController.text,
      'LName': _lastNameController.text,
      'Email': _emailController.text,
      'UserName': _userNameController.text,
      'Address': _locationController.text,
      'PhoneNumber': _phoneController.text,
      'Image': widget.userProfile.imageBase64 ?? '',
    };

    try {
      final response = await http.put(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );

        final updatedProfile = UserProfileModel(
          id: widget.userProfile.id,
          fName: _firstNameController.text,
          lName: _lastNameController.text,
          userName: _userNameController.text,
          email: _emailController.text,
          address: _locationController.text,
          phoneNumber: _phoneController.text,
          imageBase64: widget.userProfile.imageBase64,
        );

        Navigator.pop(context, updatedProfile);
      } else {
        throw Exception('Failed to update user profile: ${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      body:  Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 119,
                          height: 119,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color(0xFFC48A7C),
                              width: 2.2,
                            ),
                          ),
                          child: ClipOval(
                            child: widget.userProfile.imageBase64 != null && widget.userProfile.imageBase64!.isNotEmpty
                                ? Image.memory(
                              base64Decode(widget.userProfile.imageBase64!),
                              width: 119,
                              height: 119,
                              fit: BoxFit.cover,
                            )
                                : Image.asset(
                              'assets/images/default_profile.png',
                              width: 119,
                              height: 119,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 20,
                            child: Icon(
                              Icons.camera_alt,
                              color: Color(0xFFC78879),
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                    _buildInputField(
                      width: width,
                      icon: Icons.person,
                      hintText: 'First Name',
                      controller: _firstNameController,
                      validator: (value) => _validateNameLength(value, "First Name"),
                    ),
                    SizedBox(height: 9),
                    _buildInputField(
                      width: width,
                      icon: Icons.person,
                      hintText: 'Last Name',
                      controller: _lastNameController,
                      validator: (value) => _validateNameLength(value, "Last Name"),
                    ),
                    SizedBox(height: 9),
                    _buildInputField(
                      width: width,
                      icon: Icons.person,
                      hintText: 'User Name',
                      controller: _userNameController,
                      validator: (value) => _validateNotEmpty(value, "User Name"),
                    ),
                    SizedBox(height: 9),
                    _buildInputField(
                      width: width,
                      icon: Icons.email,
                      hintText: 'Email',
                      controller: _emailController,
                      validator: _validateEmail,
                    ),
                    SizedBox(height: 9),
                    _buildInputField(
                      width: width,
                      icon: Icons.location_on,
                      hintText: 'Location',
                      controller: _locationController,
                      validator: (value) => _validateNotEmpty(value, "Location"),
                    ),
                    SizedBox(height: 9),
                    _buildInputField(
                      width: width,
                      icon: Icons.phone,
                      hintText: 'Phone Number',
                      controller: _phoneController,
                      validator: _validatePhoneNumber,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 55,
            left: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_outlined),
                  color: Color(0xFFC78C7E),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  "Edit Info",
                  style: GoogleFonts.marmelad(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFC78C7E),
                  ),
                )
              ],
            ),
          ),
          Positioned(
            bottom: 80,
            right: 60,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isFormValid,
              builder: (context, isFormValid, child) {
                return ValueListenableBuilder<bool>(
                  valueListenable: _isLoading,
                  builder: (context, isLoading, child) {
                    return GestureDetector(
                      onTap: isFormValid && !isLoading
                          ? () async {
                        try {
                          await _updateUserProfile();
                          if (widget.userProfile.imageBase64 != null) {
                            await _updateProfilePhoto(widget.userProfile.imageBase64!);
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to update profile: $e')),
                          );
                        }
                      }
                          : null,
                      child: CircleAvatar(
                        backgroundColor: isFormValid && !isLoading ? Color(0xFFE8AE99) : Color(0xFFF1DFD5),
                        radius: 23,
                        child: isLoading
                            ? CircularProgressIndicator(color: Colors.white)
                            : Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required double width,
    required IconData icon,
    required String hintText,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width * 0.72,
          padding: EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/InputBorder4_enhanced.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                Icon(icon, color: Color(0xFFC39084)),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    validator: validator,
                    onChanged: (value) => _updateFormState(),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(
                        color: Color(0xFFC39084), // Hint text style
                        fontSize: 14, // Same font size as input text
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      fontSize: 14, // Ensure same font size as hint text
                      color: Color(0xFFC39084), // Same color as hint text
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  String? _validateNotEmpty(String? value, String fieldName) {
    return value == null || value.isEmpty ? '$fieldName cannot be empty' : null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value) ? null : 'Please enter a valid email address';
  }

  String? _validateNameLength(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName cannot be empty';
    if (value.length < 3) return '$fieldName must be at least 3 characters long';
    if (value.length > 30) return '$fieldName cannot exceed 30 characters';
    return null;
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) return 'Phone number cannot be empty';
    final phoneRegex = RegExp(r'^\+?\d{10,15}$');
    return phoneRegex.hasMatch(value) ? null : 'Please enter a valid phone number';
  }
}
