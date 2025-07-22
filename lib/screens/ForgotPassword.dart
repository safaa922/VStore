import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import for JSON decoding

import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/TokenResetPassword.dart'; // Import Token page

class ForgotPassword extends StatefulWidget {
  @override
  _ForgotPasswordState createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final TextEditingController emailController = TextEditingController();
  String? emailError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 145,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(1.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconBox(),
                    Text('Forgot Password?', style: headingStyle),
                    SizedBox(height: 13),
                    Text(
                      'Please enter your email address\nfor password recovery',
                      textAlign: TextAlign.center,
                      style: subheadingStyle,
                    ),
                    SizedBox(height: 38),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.64,
                      child: CustomTextField(
                        label: 'Email',
                        icon: Icons.email,
                        controller: emailController,
                        errorText: emailError,
                      ),
                    ),
                    SizedBox(height: 47),
                    ResetButton(onPressed: () => _submitEmail(context)),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 57,
            left: 24,
            child: IconButton(
              icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFC39084), size: 28),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitEmail(BuildContext context) async {
    final email = emailController.text;

    setState(() {
      emailError = null; // Clear any previous errors
    });

    if (email.isEmpty) {
      setState(() {
        emailError = 'Please enter your email';
      });
      return;
    }

    final url = Uri.parse('http://vstore.runasp.net/api/Account/ForgotPassword');
    try {
      final response = await http.post(
        url,
        body: {'Email': email},
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        // Extract token and reset link from the response
        final token = responseData['token'];
        final resetLink = responseData['resetLink']; // Use if needed

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TokenResetPassword(
              token: token, // Pass token to the token page
              email: email,
            ),
          ),
        );
      } else {
        setState(() {
          emailError = 'Failed to send email: User Not Found \n or email is Not Confirmed';
        });
      }
    } catch (error) {
      setState(() {
        emailError = 'Error: $error';
      });
    }
  }
}

class IconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.asset(
        'assets/images/Envelope4.png',
        width: 210,
        height: 210,
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;
  final bool obscureText;
  final String? errorText;

  CustomTextField({
    required this.label,
    required this.icon,
    required this.controller,
    this.obscureText = false,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: TextStyle(color: Color(0xFFB0715F)), // Set input text color
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFB0715F)),
        hintText: label,
        hintStyle: TextStyle(color: Color(0xFFB0715F)),
        contentPadding: EdgeInsets.only(top: 12), // 👈 Add this line
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
        ),
        errorText: errorText,
      ),

    );
  }
}

class ResetButton extends StatelessWidget {
  final VoidCallback onPressed;

  ResetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFBD7564),
        padding: EdgeInsets.symmetric(horizontal: 103, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text('Next', style: TextStyle(fontSize: 21, color: Colors.white)),
    );
  }
}

// Text Styles
final headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFBA7F71));
final subheadingStyle = TextStyle(color: Color(0xFFC4A090), fontSize: 13, fontWeight: FontWeight.w500);
