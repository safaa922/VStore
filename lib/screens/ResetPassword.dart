import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:virtual_store/screens/Login.dart';

class ResetPassword extends StatefulWidget {
  final String email;
  final String token; // Token passed from the previous step

  ResetPassword({required this.email, required this.token});

  @override
  _ResetPasswordState createState() => _ResetPasswordState();
}

class _ResetPasswordState extends State<ResetPassword> {
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  String? newPasswordError;
  String? confirmPasswordError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBox(),
                Text('Reset Your Password', style: headingStyle),
                SizedBox(height: 10),
                Text(
                  'Create a new password to access your account',
                  textAlign: TextAlign.center,
                  style: subheadingStyle,
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.64,
                  child: CustomTextField(
                    label: 'New Password',
                    icon: Icons.lock,
                    obscureText: true,
                    controller: newPasswordController,
                    errorText: newPasswordError,
                  ),
                ),
                SizedBox(height: 23),
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.64,
                  child: CustomTextField(
                    label: 'Confirm Password',
                    icon: Icons.check_circle,
                    obscureText: true,
                    controller: confirmPasswordController,
                    errorText: confirmPasswordError,
                  ),
                ),
                SizedBox(height: 43),
                ResetButton(
                  onPressed: () {
                    resetPassword();
                  },
                ),
                SizedBox(height: 26),
              ],
            ),
          ),
          Positioned(
            top: 62,
            left: 24,
            child: IconButton(
              icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFB0715F), size: 28),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void resetPassword() {
    final newPassword = newPasswordController.text;
    final confirmPassword = confirmPasswordController.text;

    setState(() {
      newPasswordError = newPassword.isEmpty ? 'Please enter a new password' : null;
      confirmPasswordError = confirmPassword.isEmpty
          ? 'Please confirm your password'
          : (newPassword != confirmPassword ? 'Passwords do not match' : null);
    });

    if (newPasswordError == null && confirmPasswordError == null) {
      _performResetPassword();
    }
  }

  Future<void> _performResetPassword() async {
    try {
      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Account/ResetPassword'),
        body: {
          'Email': widget.email,
          'Token': widget.token, // Token passed from the previous screen
          'NewPassword': newPasswordController.text,
          'ConfirmPassword': confirmPasswordController.text,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset successful')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to reset password. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred. Please try again later.')),
      );
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          style: TextStyle(color: Color(0xFFB0715F)), // Set input text color
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFB0715F)),
            hintText: label,
            hintStyle: TextStyle(color: Color(0xFFB0715F)),
            contentPadding: EdgeInsets.only(top: 13), // 👈 Add this line
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
            ),
            errorText: errorText,
          ),
        ),

      ],
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
        padding: EdgeInsets.symmetric(horizontal: 69, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text('Reset Password', style: TextStyle(fontSize: 21, color: Colors.white)),
    );
  }
}

final headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFB0715F));
final subheadingStyle = TextStyle(color: Color(0xFFC4A090), fontSize: 13, fontWeight: FontWeight.bold);
