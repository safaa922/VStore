import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/Buyer_SignUpCont.dart';
import 'package:virtual_store/screens/Login.dart';

class BuyerSignup extends StatefulWidget {
  static String id = 'Signup';
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  @override
  _BuyerSignupState createState() => _BuyerSignupState();
}

class _BuyerSignupState extends State<BuyerSignup> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final double backgroundWidthFactor= 1.0; // Width factor for the background
  final double backgroundHeightFactor= 1.01; // Height factor for the background



  bool _firstNameError = false;
  bool _lastNameError = false;
  bool _userNameError = false;
  bool _emailError = false;

  // FocusNodes for each field
  final FocusNode _firstNameFocus = FocusNode();
  final FocusNode _lastNameFocus = FocusNode();
  final FocusNode _userNameFocus = FocusNode();
  final FocusNode _emailFocus = FocusNode();

  @override
  void dispose() {
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _userNameFocus.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // Validation functions
  String? _validateNotEmpty(String? value, String fieldName) {
    return value == null || value.isEmpty ? '$fieldName cannot be empty' : null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email cannot be empty';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    return emailRegex.hasMatch(value)
        ? null
        : 'Please enter a valid email address, \nemail must contain @ and must end with .com';
  }

  String? _validateNameLength(String? value, String fieldName) {
    if (value == null || value.isEmpty) return '$fieldName cannot be empty';
    if (value.length < 3) return '$fieldName must be at least 3 characters long';
    if (value.length > 30) return '$fieldName cannot exceed 30 characters';
    return null;
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
              width: width * backgroundWidthFactor, // Dynamic width
              height: height * backgroundHeightFactor-68, // Dynamic height
              child: Image.asset(
                "assets/images/SignUpBackground4New.png",
                fit: BoxFit.fill,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Form(
                key: widget.globalKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 30), // Increased space
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'First Name',
                        controller: _firstNameController,
                        validator: (value) =>
                            _validateNameLength(value, "First Name"),
                        error: _firstNameError,
                        focusNode: _firstNameFocus,
                        onChanged: (value) {
                          setState(() {
                            _firstNameError = _validateNameLength(value, "First Name") != null;
                          });
                        },
                      ),
                      SizedBox(height: 15), // Increased space
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'Last Name',
                        controller: _lastNameController,
                        validator: (value) =>
                            _validateNameLength(value, "Last Name"),
                        error: _lastNameError,
                        focusNode: _lastNameFocus,
                        onChanged: (value) {
                          setState(() {
                            _lastNameError = _validateNameLength(value, "Last Name") != null;
                          });
                        },
                      ),
                      SizedBox(height: 15), // Increased space
                      _buildInputField(
                        width: width,
                        icon: Icons.person,
                        hintText: 'User Name',
                        controller: _userNameController,
                        validator: (value) =>
                            _validateNotEmpty(value, "User Name"),
                        error: _userNameError,
                        focusNode: _userNameFocus,
                        onChanged: (value) {
                          setState(() {
                            _userNameError = _validateNotEmpty(value, "User Name") != null;
                          });
                        },
                      ),
                      SizedBox(height: 15), // Increased space
                      _buildInputField(
                        width: width,
                        icon: Icons.email,
                        hintText: 'Email',
                        controller: _emailController,
                        validator: _validateEmail,
                        error: _emailError,
                        focusNode: _emailFocus,
                        onChanged: (value) {
                          setState(() {
                            _emailError = _validateEmail(value) != null;
                          });
                        },
                      ),
                      SizedBox(height: 30), // Increased space
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            // Validate all fields
                            _firstNameError = _validateNameLength(_firstNameController.text, "First Name") != null;
                            _lastNameError = _validateNameLength(_lastNameController.text, "Last Name") != null;
                            _userNameError = _validateNotEmpty(_userNameController.text, "User Name") != null;
                            _emailError = _validateEmail(_emailController.text) != null;
                          });

                          if (!_firstNameError && !_lastNameError && !_userNameError && !_emailError) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyerSignup_Cont(
                                  firstName: _firstNameController.text,
                                  lastName: _lastNameController.text,
                                  userName: _userNameController.text,
                                  email: _emailController.text,
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          height: 60,
                          width: width * 0.72,
                          decoration: BoxDecoration(
                            color: Color(0xFFEBDFDA),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Center(
                            child: Text(
                              'Next',
                              style: GoogleFonts.marmelad(
                                fontSize: 25,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20), // Increased space
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LoginScreen()),
                          );
                        },
                        child: Text(
                          "Already have an account?",
                          style: TextStyle(
                            fontSize: 14.8,
                            color: Color(0xFFC79E95),
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
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
    required bool error,
    required FocusNode focusNode,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width * 0.69,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/InputBorder4_enhanced.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                SizedBox(width: 7),
                Icon(icon, color: Color(0xFFC1978C)),
                SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    validator: validator,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: Color(0xFFC1978C)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 16, color: Color(0xFFC1978C)), // Text input color set to red
                    onChanged: onChanged,
                  ),

                ),
              ],
            ),
          ),
        ),
        // Error message with padding
        if (error)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 5),
            child: Text(
              validator(controller.text) ?? '',
              style: TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
      ],
    );
  }
}

