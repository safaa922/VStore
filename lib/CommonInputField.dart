import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:virtual_store/constants.dart';

class OwnerSignupUI extends StatelessWidget {
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final File? selectedImage;
  final Function onPickImage;
  final Function onSignUp;
  final String buttonText;

  OwnerSignupUI({
    required this.phoneController,
    required this.passwordController,
    required this.selectedImage,
    required this.onPickImage,
    required this.onSignUp,
    this.buttonText = 'Sign Up',
  });

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Stack(
      children: [
        Positioned(
          top: 50,
          left: 20,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: K_black, size: 30),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        Positioned(
          top: 180,
          left: 64,
          child: Column(
            children: [
              SizedBox(height: 40),
              _buildInputField(width, Icons.phone, 'Phone Number', phoneController),
              SizedBox(height: 20),
              _buildInputField(width, Icons.lock, 'Password', passwordController, obscureText: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => onPickImage(),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: K_black),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: selectedImage == null
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.image, color: K_black),
                    SizedBox(width: 8),
                    Text('Tap to choose Image', style: TextStyle(color: K_black)),
                  ],
                )
                    : Container(
                  width: width * 0.7,
                  height: 200,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(selectedImage!),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 529,
          left: 65,
          child: GestureDetector(
            onTap: () => onSignUp(),
            child: Container(
              height: 66,
              width: width * 0.7,
              decoration: BoxDecoration(
                color: K_black,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  style: GoogleFonts.marmelad(fontSize: 25, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(double width, IconData icon, String hintText, TextEditingController controller, {bool obscureText = false}) {
    return Stack(
      children: [
        Image.asset(
          "assets/images/inputBorder3_trans.png",
          width: width * 0.7,
        ),
        Positioned(
          top: 10,
          left: 10,
          child: Row(
            children: [
              Icon(icon, color: K_black),
              SizedBox(width: 10),
              Container(
                width: width * 0.55,
                child: TextField(
                  controller: controller,
                  obscureText: obscureText,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
