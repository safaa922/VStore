import 'package:flutter/material.dart';
import 'package:virtual_store/constants.dart';
import 'package:google_fonts/google_fonts.dart';

class Signup_Cont extends StatefulWidget {
  static String id = 'Signup_Cont';

  @override
  _Signup_ContState createState() => _Signup_ContState();
}

class _Signup_ContState extends State<Signup_Cont> {
  int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
                _buildInputField(width, Icons.group, 'User Type'),
                SizedBox(height: 20),
                _buildInputField(width, Icons.phone, 'Phone Number'),
                SizedBox(height: 20),
                _buildInputField(width, Icons.lock, 'Password', obscureText: true),
                SizedBox(height: 20),
                _buildInputField(width, Icons.lock, 'Confirm Password', obscureText: true),
              ],
            ),
          ),
          Positioned(
            top: 579,
            left: 65,
            child: Column(
              children: [
                Container(
                  height: 66,
                  width: width * 0.7,
                  decoration: BoxDecoration(
                    color: K_black,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: K_black),
                  ),
                  child: Center(
                    child: Text(
                      'Sign Up',
                      style: GoogleFonts.marmelad(
                        fontSize: 25,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  "Already have an account?",
                  style: TextStyle(
                    fontSize: 17,
                    color: K_dustyRose,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 718,
            left: 136,
            child: Image.asset(
              "assets/images/Waves2Trans.png",
              width: width * 0.67,
            ),
          ),
          Positioned(
            bottom: 70,
            left: width * 0.5 - 8,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (_currentPage == 1) {
                      Navigator.pop(context);
                    }
                  },
                  child: _buildDot(_currentPage == 0),
                ),
                SizedBox(width: 12),
                _buildDot(_currentPage == 1),
              ],
            ),
          ),
          Positioned(
            bottom: 727,
            right: 99,
            child: Image.asset(
              "assets/images/WavesTrans.png",
              width: width * 0.77,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(double width, IconData icon, String hintText, {bool obscureText = false}) {
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

  Widget _buildDot(bool isActive) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: isActive ? K_dustyRose : Colors.black,
        shape: BoxShape.circle,
      ),
    );
  }
}
