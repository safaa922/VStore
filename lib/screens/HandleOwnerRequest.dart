import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/Login.dart'; // Adjust if you don't have this file

class Handleownerrequest extends StatefulWidget {
  @override
  _OwnerRequestFormState createState() => _OwnerRequestFormState();
}

Future<void> handleOwnerRequest(String email, String shopName, String shopDescription, BuildContext context) async {
  final url = Uri.parse('http://vstore.runasp.net/api/Owner/HandleOwnerRequest?Email=$email');
  final headers = {'Content-Type': 'application/json'};
  final body = jsonEncode({
    'shop_Name': shopName,
    'shop_Description': shopDescription,
  });

  final response = await http.patch(url, headers: headers, body: body);

  if (response.statusCode == 200) {
    // Show AlertDialog on success
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Welcome'),
          content: const Text('Request successfully sent'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  } else {
    print('Request failed with status: ${response.statusCode}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Request failed. Please try again.')),
    );
  }
}

class _OwnerRequestFormState extends State<Handleownerrequest> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopDescriptionController = TextEditingController();

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      handleOwnerRequest(
        _emailController.text,
        _shopNameController.text,
        _shopDescriptionController.text,
        context, // Pass the context to handleSnackbar
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Positioned(
              top: height * 0.858, // Adjusted with MediaQuery
              left: width * 0.32, // Adjusted with MediaQuery
              child: Image.asset(
                "assets/images/Waves2Trans.png", // Adjust image path
                width: width * 0.68,
              ),
            ),
            Positioned(
              top: height * 0.1, // Adjusted with MediaQuery
              left: width * 0.06, // Adjusted with MediaQuery
              child: IconButton(
                icon: Icon(CupertinoIcons.left_chevron, color: K_black2, size: 28),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Positioned(
              bottom: height * 0.8953366, // Adjusted with MediaQuery
              right: width * 0.237, // Adjusted with MediaQuery
              child: Image.asset(
                "assets/images/WavesTrans.png", // Adjust image path
                width: width * 0.768,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: width * 0.08, vertical: height * 0.285), // Adjusted padding
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [],
                    ),
                    _buildInputField(width, Icons.email, 'Email', _emailController, 'Please enter a valid email', isEmail: true),
                    SizedBox(height: height * 0.02), // Adjusted spacing
                    _buildInputField(width, Icons.business, 'Shop Name', _shopNameController, 'Please enter your shop name'),
                    SizedBox(height: height * 0.02), // Adjusted spacing
                    _buildInputField(width, Icons.description, 'Shop Description', _shopDescriptionController, 'Please enter your shop description'),
                    SizedBox(height: height * 0.08), // Adjusted spacing
                    GestureDetector(
                      onTap: _submitForm,
                      child: Container(
                        height: height * 0.08, // Adjusted height
                        width: width * 0.7,
                        decoration: BoxDecoration(
                          color: K_black,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Center(
                          child: Text(
                            'Submit',
                            style: GoogleFonts.marmelad(
                              fontSize: 25,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: height * 0.02), // Adjusted spacing
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(double width, IconData icon, String hintText, TextEditingController controller, String validationMessage, {bool isEmail = false}) {
    return Stack(
      children: [
        Image.asset(
          "assets/images/inputBorder3_trans.png", // Adjust image path
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
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    border: InputBorder.none,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return validationMessage;
                    }

                    // Email validation if isEmail is true
                    if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Enter a valid email address';
                    }

                    return null;
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
