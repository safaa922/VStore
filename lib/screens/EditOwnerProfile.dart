
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

import 'package:virtual_store/screens/OwnerProfile.dart';

class EditOwnerProfile extends StatefulWidget {
  final OwnerProfileModel ownerProfile;

  EditOwnerProfile({required this.ownerProfile});

  @override
  _EditOwnerProfileState createState() => _EditOwnerProfileState();
}

class _EditOwnerProfileState extends State<EditOwnerProfile> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopDescriptionController = TextEditingController();
  final ValueNotifier<bool> _isFormValid = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _addListeners();
  }

  void _initializeControllers() {
    _firstNameController.text = widget.ownerProfile.fName ?? '';
    _lastNameController.text = widget.ownerProfile.lName ?? '';
    _userNameController.text = widget.ownerProfile.userName ?? '';
    _emailController.text = widget.ownerProfile.email ?? '';
    _locationController.text = widget.ownerProfile.address ?? '';
    _phoneController.text = widget.ownerProfile.phoneNumber ?? '';
    _shopNameController.text = widget.ownerProfile.shopName ?? '';
    _shopDescriptionController.text = widget.ownerProfile.shop_description ?? '';
  }

  void _addListeners() {
    _firstNameController.addListener(_updateFormState);
    _lastNameController.addListener(_updateFormState);
    _emailController.addListener(_updateFormState);
    _userNameController.addListener(_updateFormState);
    _locationController.addListener(_updateFormState);
    _phoneController.addListener(_updateFormState);
    _shopNameController.addListener(_updateFormState);
    _shopDescriptionController.addListener(_updateFormState);
  }

  void _updateFormState() {
    final isFormValid = _firstNameController.text.isNotEmpty &&
        _lastNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _userNameController.text.isNotEmpty &&
        _locationController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _shopNameController.text.isNotEmpty &&
        _shopDescriptionController.text.isNotEmpty;
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
          widget.ownerProfile.imageBase64 = base64Image;
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
    final url = Uri.parse('http://vstore.runasp.net/api/Owner/Update_photo/${widget.ownerProfile.id}');

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

  Future<void> _updateOwnerProfile() async {
    _isLoading.value = true;

    final url = Uri.parse('http://vstore.runasp.net/api/Owner/Update_Owner/${widget.ownerProfile.id}');

    final Map<String, String> requestBody = {
      'FName': _firstNameController.text,
      'LName': _lastNameController.text,
      'Email': _emailController.text,
      'UserName': _userNameController.text,
      'Address': _locationController.text,
      'PhoneNumber': _phoneController.text,
      'ShopName': _shopNameController.text,
      'ShopDescription': _shopDescriptionController.text,
      'Image': widget.ownerProfile.imageBase64 ?? '',
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

        final updatedProfile = OwnerProfileModel(
          id: widget.ownerProfile.id,
          fName: _firstNameController.text,
          lName: _lastNameController.text,
          userName: _userNameController.text,
          email: _emailController.text,
          address: _locationController.text,
          phoneNumber: _phoneController.text,
          shopName: _shopNameController.text,
          shop_description: _shopDescriptionController.text,
          imageBase64: widget.ownerProfile.imageBase64,
        );

        Navigator.pop(context, updatedProfile);
      } else {
        throw Exception('Failed to update owner profile: ${response.body}');
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
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 150, left: 32, right: 32, bottom: 100),
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
                          child: widget.ownerProfile.imageBase64 != null && widget.ownerProfile.imageBase64!.isNotEmpty
                              ? Image.memory(
                            base64Decode(widget.ownerProfile.imageBase64!),
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
                  SizedBox(height: 50),

                  // Wrap two fields in a row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'First Name',
                        controller: _firstNameController,
                        validator: (value) => _validateNameLength(value, "First Name"),
                      ),
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'Last Name',
                        controller: _lastNameController,
                        validator: (value) => _validateNameLength(value, "Last Name"),
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'User Name',
                        controller: _userNameController,
                        validator: (value) => _validateNotEmpty(value, "User Name"),
                      ),
                      _buildInputField(
                        width: width,
                        icon: Icons.email,
                        hintText: 'Email',
                        controller: _emailController,
                        validator: _validateEmail,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputField(
                        width: width,
                        icon: Icons.location_on,
                        hintText: 'Location',
                        controller: _locationController,
                        validator: (value) => _validateNotEmpty(value, "Location"),
                      ),
                      _buildInputField(
                        width: width,
                        icon: Icons.phone,
                        hintText: 'Phone Number',
                        controller: _phoneController,
                        validator: _validatePhoneNumber,
                      ),
                    ],
                  ),
                  SizedBox(height: 18),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputField(
                        width: width,
                        icon: Icons.store,
                        hintText: 'Shop Name',
                        controller: _shopNameController,
                        validator: (value) => _validateNotEmpty(value, "Shop Name"),
                      ),
                      _buildInputField(
                        width: width,
                        icon: Icons.description,
                        hintText: 'Shop Description',
                        controller: _shopDescriptionController,
                        validator: (value) => _validateNotEmpty(value, "Shop Description"),
                      ),
                    ],
                  ),
                ],
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
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 17,
              right: 30,
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
                            await _updateOwnerProfile();
                            if (widget.ownerProfile.imageBase64 != null) {
                              await _updateProfilePhoto(widget.ownerProfile.imageBase64!);
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
          width: width * 0.41,
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
                      hintStyle: TextStyle(color: Color(0xFFC39084)),
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
