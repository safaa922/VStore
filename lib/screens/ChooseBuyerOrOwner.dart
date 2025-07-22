import 'package:flutter/material.dart';
import 'package:virtual_store/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:virtual_store/screens/CRUD_PROD/Create_Stock.dart';
import 'package:virtual_store/screens/CRUD_PROD/OwnerProdDetails.dart';
import 'package:virtual_store/screens/Location.dart';
import 'package:virtual_store/screens/Notification.dart';
import 'package:virtual_store/screens/OwnerProfile.dart';
import 'package:virtual_store/screens/OwnerSignUp.dart';
import 'package:virtual_store/screens/Buyer_SignUp.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/screens/Shops.dart';
import 'package:virtual_store/screens/UserProfile.dart';

class Choosebuyerorowner extends StatefulWidget {
  final double backgroundWidthFactor; // Width factor for the background
  final double backgroundHeightFactor; // Height factor for the background

  Choosebuyerorowner({
    this.backgroundWidthFactor = 1.0,
    this.backgroundHeightFactor = 1.0,
  });

  @override
  _ChoosebuyerorownerState createState() => _ChoosebuyerorownerState();
}

class _ChoosebuyerorownerState extends State<Choosebuyerorowner> {
  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Image
          Align(
            alignment: Alignment.center,
            child: Container(
              width: width * widget.backgroundWidthFactor, // Dynamic width
              height: height * widget.backgroundHeightFactor-68, // Dynamic height
              child: Image.asset(
                "assets/images/BgChooseBuyerOrOwner6.png",
                fit: BoxFit.fill,
              ),
            ),
          ),

          // Foreground content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 54),
                Text(
                  "What best describes you?",
                  style: GoogleFonts.marmelad(
                    fontSize: 18,
                    color: Color(0xFFC7A798),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 44),

                // Button for Buyer Signup
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => BuyerSignup()),
                    );
                  },
                  child: Container(
                    height: 60,
                    width: width * 0.7,
                    decoration: BoxDecoration(
                      color: Color(0xFFBD7564),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        "Buyer",
                        style: GoogleFonts.marmelad(
                          fontSize: 19,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Button for Owner Signup
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => OwnerSignup()),
                    );
                  },
                  child: Container(
                    height: 60,
                    width: width * 0.7,
                    decoration: BoxDecoration(
                      color: Color(0xFFEDE1D9),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        "Shop Owner",
                        style: GoogleFonts.marmelad(
                          fontSize: 19,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 37),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: Text(
                    "Already have an account?",
                    style: TextStyle(
                      fontSize: 15,
                      color: Color(0xFFC7A798),
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),




                SizedBox(height: 50),

              ],
            ),
          ),
        ],
      ),
    );
  }
}
