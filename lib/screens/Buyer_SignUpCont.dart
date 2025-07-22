import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:mime/mime.dart';

import 'Location.dart';

class BuyerSignup_Cont extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;
  final String userName;
  final double backgroundWidthFactor; // Width factor for the background
  final double backgroundHeightFactor; // Height factor for the background

  BuyerSignup_Cont({
    this.backgroundWidthFactor = 1.0,
    this.backgroundHeightFactor = 1.01,
    required this.firstName,
    required this.lastName,
    required this.userName,
    required this.email,
  });

  @override
  _BuyerSignup_ContState createState() => _BuyerSignup_ContState();
}

class _BuyerSignup_ContState extends State<BuyerSignup_Cont> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  File? _selectedImage;

  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  String? _imageError;

  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery);
      if (pickedFile != null) {
        final mimeType = lookupMimeType(pickedFile.path);
        if (mimeType != null && mimeType.startsWith('image/')) {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _imageError = null;
          });
        } else {
          setState(() {
            _imageError = 'Please select a valid image file';
            _selectedImage = null;
          });
        }
      }
    } catch (e) {
      print("Image picker error: $e");
    }
  }

  Future<void> _BuyerSignUp() async {
    setState(() {
      _phoneError = _phoneController.text.isEmpty
          ? 'Phone number cannot be empty'
          : (_phoneController.text.length == 11 &&
          RegExp(r'^\d{11}$').hasMatch(_phoneController.text))
          ? null
          : 'Phone number must be exactly 11 digits';

      _passwordError = _passwordController.text.isEmpty
          ? 'Password cannot be empty'
          : (_passwordController.text.length < 8
          ? 'Password must be at least 8 characters'
          : (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(
          _passwordController.text)
          ? 'Password must contain a special character'
          : (!RegExp(r'\d').hasMatch(_passwordController.text)
          ? 'Password must contain at least one number'
          : null)));

      _confirmPasswordError =
      (_passwordController.text != _confirmPasswordController.text)
          ? 'Passwords do not match'
          : null;

      _imageError = _selectedImage == null ? 'Please choose an image' : null;
    });

    if (_phoneError != null || _passwordError != null ||
        _confirmPasswordError != null || _imageError != null) {
      return;
    }

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://vstore.runasp.net/api/Account/User_Register'),
      );

      request.fields['FName'] = widget.firstName;
      request.fields['LName'] = widget.lastName;
      request.fields['Email'] = widget.email;
      request.fields['Address'] = _addressController.text;
      request.fields['PhoneNumber'] = _phoneController.text;
      request.fields['Password'] = _passwordController.text;
      request.fields['ConfirmPassword'] = _confirmPasswordController.text;
      request.fields['UserName'] = widget.userName;

      if (_selectedImage != null) {
        request.files.add(
            await http.MultipartFile.fromPath('Image', _selectedImage!.path));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final decodedResponse = json.decode(responseBody);
        String? userId = decodedResponse['id']?.toString();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Welcome', style: TextStyle(color: Color(0xFFB0735A)),),
              content: const Text('You have successfully signed up!', style: TextStyle(color: Color(0xFFB0735A)),),
              actions: [
                TextButton(
                  onPressed: ()
                  {
                    Navigator.of(context).pop();
                    if (userId != null) {
                      Navigator.pushReplacement(
                        context,

                        MaterialPageRoute(builder: (context) =>
                            LocationPickerScreen(userId: userId)),
                      );
                    }

                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      } else {
        final responseData = json.decode(responseBody);
        _showErrorDialog(responseData['error'] ??
            'Sign up failed.\nEmail or username might be already taken.');
      }
    } catch (e) {
      print("Error: $e");
      _showErrorDialog("An error occurred. Please try again later.");
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white, // Set background to white
        title: Text(
          "Error",
          style: TextStyle(color: Color(0xFFB0735A)), // Set title text color to red
        ),
        content: Text(
          message,
          style: TextStyle(color: Color(0xFFB0735A)), // Set content text color to red
        ),
        actions: [
          TextButton(
            child: Text(
              "OK",
              style: TextStyle(color:Color(0xFFB0735A)), // Set button text color to red
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(double width, IconData icon, String hintText, TextEditingController controller,
      {bool obscureText = false, String? errorText, required Function(String) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            Image.asset(
              "assets/images/InputBorder4_enhanced.png",
              width: width * 0.7,
            ),
            Positioned(
              top: 10,
              left: 10,
              child: Row(
                children: [
                  SizedBox(width: 7),
                  Icon(icon, color: Color(0xFFC1978C)),
                  SizedBox(width: 10),
                  Container(
                    width: width * 0.55,
                    child: TextField(
                      controller: controller,
                      obscureText: obscureText,
                      onChanged: onChanged, // Validate on change
                      decoration: InputDecoration(
                        hintText: hintText,
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Color(0xFFC1978C)),
                      ),
                      style: TextStyle(fontSize: 16, color: Color(0xFFC1978C)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 5),
            child: Text(
              errorText,
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
        statusBarColor: Colors.transparent
    ),);

    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              width: width * widget.backgroundWidthFactor,
              height: height * widget.backgroundHeightFactor - 68,
              child: Image.asset(
                "assets/images/SignUpBackground4New.png",
                fit: BoxFit.fill,
              ),
            ),
          ),
          Positioned(
            top: 60,
            left: 20,
            child: IconButton(
              icon: Icon(
                  Icons.arrow_back_ios_new_outlined, color: Color(0xFFBD7564),
                  size: 30),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 40),
                  _buildInputField(
                    width,
                    Icons.phone,
                    'Phone Number',
                    _phoneController,
                    errorText: _phoneError,
                    onChanged: (value) {
                      setState(() {
                        _phoneError = value.isEmpty
                            ? 'Phone number cannot be empty'
                            : (value.length == 11 &&
                            RegExp(r'^\d{11}$').hasMatch(value))
                            ? null
                            : 'Phone number must be exactly 11 digits';
                      });
                    },
                  ),
                  SizedBox(height: 13),
                  _buildInputField(
                    width,
                    Icons.location_on,
                    'Address',
                    _addressController,
                    onChanged: (value) {},
                  ),
                  SizedBox(height: 13),
                  _buildInputField(
                    width,
                    Icons.lock,
                    'Password',
                    _passwordController,
                    obscureText: true,
                    errorText: _passwordError,
                    onChanged: (value) {
                      setState(() {
                        _passwordError = value.isEmpty
                            ? 'Password cannot be empty'
                            : (value.length < 8
                            ? 'Password must be at least 8 characters'
                            : (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(
                            value)
                            ? 'Password must contain a special character'
                            : (!RegExp(r'\d').hasMatch(value)
                            ? 'Password must contain at least one number'
                            : null)));
                      });
                    },
                  ),
                  SizedBox(height: 13),
                  _buildInputField(
                    width,
                    Icons.lock,
                    'Confirm Password',
                    _confirmPasswordController,
                    obscureText: true,
                    errorText: _confirmPasswordError,
                    onChanged: (value) {
                      setState(() {
                        _confirmPasswordError =
                        value != _passwordController.text
                            ? 'Passwords do not match'
                            : null;
                      });
                    },
                  ),
                  SizedBox(height: 13),
                  ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 0.7, horizontal: 30),
                      backgroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: Container(
                      height: 68,
                      decoration: BoxDecoration(
                        border: Border.all(width: 3, color: Colors.transparent),
                        image: DecorationImage(
                          image: AssetImage('assets/images/InputBorder4_enhanced.png'),
                          fit: BoxFit.contain,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage == null
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 43),
                          Icon(Icons.camera_alt, color: Color(0xFFC1978C), size: 24),
                          SizedBox(width: 10),
                          Text(
                            'Choose an Image',
                            style: TextStyle(
                              color: Color(0xFFC1978C),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),

                        ],
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, color: K_dustyRose, size: 28),
                          SizedBox(width: 10),
                          Text(
                            _selectedImage!.path.split('/').last,
                            style: TextStyle(
                              color: Color(0xFFC1978C),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_imageError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _imageError!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(height: 20),
                  ElevatedButton(
                  onPressed: _BuyerSignUp,
                  child: Text(
                  "Sign Up",
                  style: GoogleFonts.marmelad(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 23,
                  ),
                  ),
                  style: ElevatedButton.styleFrom(
                  minimumSize: Size(width * 0.70, 64),
                  backgroundColor: Color(0xFFB46F5B),
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                  ),),),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}