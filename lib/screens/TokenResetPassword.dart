import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:virtual_store/screens/ResetPassword.dart';

class TokenResetPassword extends StatefulWidget {
  final String token;
  final String email;

  TokenResetPassword({required this.token, required this.email});

  @override
  _TokenResetPasswordState createState() => _TokenResetPasswordState();
}

class _TokenResetPasswordState extends State<TokenResetPassword> {
  final TextEditingController tokenController = TextEditingController();
  String? tokenError;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 150,
            left: 0,
            right: 0,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    IconBox(),
                    Text('Code Verification', style: headingStyle),
                    SizedBox(height: 10),
                    Text(
                      'Please enter the Code sent to your email',
                      textAlign: TextAlign.center,
                      style: subheadingStyle,
                    ),
                    SizedBox(height: 35),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.64,
                      child: CustomTextField(
                        label: 'Token',
                        icon: Icons.lock,
                        controller: tokenController,
                        errorText: tokenError,
                      ),
                    ),
                    SizedBox(height: 45),
                    ResetButton(onPressed: _verifyToken),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 20,
            child: IconButton(
              icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFC39585), size: 28),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _verifyToken() {
    final inputToken = tokenController.text.trim();

    setState(() {
      tokenError = inputToken.isEmpty
          ? 'Please enter the Code'
          : (inputToken != widget.token ? 'Invalid Code. Please try again.' : null);
    });

    if (tokenError == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPassword(
            email: widget.email,
            token: widget.token,
          ),
        ),
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
  final String? errorText;

  CustomTextField({
    required this.label,
    required this.icon,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,

          style: TextStyle(color: Color(0xFFB0715F)), // Set input text color
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFFB0715F)),
            hintText: label,
            hintStyle: TextStyle(color: Color(0xFFB0715F)),
            contentPadding: EdgeInsets.only(top: 15), // 👈 Add this line
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFB0715F), width: 1.5),
            ),
            errorText: errorText,
          ),
        ),

        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 5.0),
            child: Text(
              errorText!,
              style: TextStyle(color:  Color(0xFFC74635), fontSize: 12),
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
        padding: EdgeInsets.symmetric(horizontal: 110, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: Text('Next', style: TextStyle(fontSize: 21, color: Colors.white)),
    );
  }
}

// Text Styles
final headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFBA7F71));
final subheadingStyle = TextStyle(color: Color(0xFFC4A090), fontSize: 13, fontWeight: FontWeight.bold);
