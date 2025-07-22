import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:virtual_store/screens/BuyerDashboard.dart';
import 'package:virtual_store/screens/Shops.dart';
import 'package:virtual_store/screens/Choosebuyerorowner.dart';
import 'package:virtual_store/screens/ForgotPassword.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:virtual_store/screens/OwnerDashBoard.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:virtual_store/screens/TryOn.dart';

import 'Location.dart';


class LoginScreen extends StatefulWidget {
  static String id = 'LoginScreen';
  final GlobalKey<FormState> globalKey = GlobalKey<FormState>();

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();
  Timer? _tokenCheckTimer;

  Future<void> saveToken(String token, String expireOn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('token_expiry', expireOn);
  }



  Future<void> checkTokenExpiration() async {
    if (!mounted) return; // Prevent calling logout if the widget is unmounted

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? expireOn = prefs.getString('token_expiry');

    print("Checking token expiration...");

    if (expireOn != null) {
      DateTime expiryTime = DateTime.parse(expireOn);
      print("Token expiry time: $expiryTime");
      print("Current time: ${DateTime.now()}");

      if (DateTime.now().isAfter(expiryTime)) {
        print("Token expired. Logging out...");
        await logoutUser(context);
      } else {
        print("Token is still valid.");
      }
    } else {
      print("No expiration time found.");
    }
  }

  Future<void> saveCartId(int cartId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('cartId', cartId);
    print('Cart ID saved: $cartId');
  }



  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the stored session token
  }


  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // بنرجع الـ ownerId
  }




  Future<void> saveCartToDatabase(String userId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? authToken = prefs.getString('auth_token');

      if (authToken == null) {
        print("Error: Missing authentication token.");
        return;
      }

      List<String> cart = prefs.getStringList('cart_$userId') ?? [];

      if (cart.isEmpty) {
        print("No items to save.");
        return;
      }

      for (String item in cart) {
        Map<String, dynamic> cartItem = jsonDecode(item);

        final url = Uri.parse(
            'http://vstore.runasp.net/api/Cart/add-product-to-cart/$userId?Product_id=${cartItem['productId']}&quantity=${cartItem['quantity']}'
        );

        var request = http.MultipartRequest("POST", url)
          ..headers.addAll({
            "Authorization": "Bearer $authToken",
          })
          ..fields['colorid'] = cartItem['color']
          ..fields['sizeid'] = cartItem['size'];

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          print("Cart item saved: ${cartItem['productId']}");
        } else {
          print("Failed to save cart item: ${cartItem['productId']} - Response: $responseBody");
        }
      }

      await prefs.remove('cart_$userId');
      print("Cart successfully saved and cleared.");
    } catch (e) {
      print('Error saving cart to database: $e');
    }
  }


  Future<void> logoutUser(BuildContext context) async {
    print("Logging out user...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('user_id');

    if (userId != null) {
      await saveCartToDatabase(userId); // Save cart before clearing user data
    }

    await prefs.clear();
    print("Cleared SharedPreferences.");

    if (!context.mounted) return;

    Future.delayed(Duration.zero, () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      print("Navigated to LoginScreen.");
    });
  }






  @override
  void initState() {
    super.initState();
    checkTokenExpiration();
    _tokenCheckTimer = Timer.periodic(Duration(seconds: 12), (timer) {
      if (mounted) {
        checkTokenExpiration();
      } else {
        timer.cancel(); // Stop the timer if the widget is unmounted
      }
    });

    _emailController.addListener(() {
      String email = _emailController.text.trim();
      if (_errors.containsKey('email')) {
        setState(() {
          _errors.remove('email'); // Remove error if the user starts typing
        });
      }
      if (email.isNotEmpty && !isValidEmail(email)) {
        setState(() {
          _errors['email'] = "Enter a valid email address, \nemail must contain @ and must end with .com";
        });
      }
    });

    _passwordController.addListener(() {
      String password = _passwordController.text.trim();
      if (_errors.containsKey('password')) {
        setState(() {
          _errors.remove('password'); // Remove the error when user starts typing
        });
      }



      if (password.isNotEmpty) { // Start validation only after the user types
        // Password dynamic validation for each case
        if (password.isEmpty) {
          setState(() {
            _errors['password'] = "Password cannot be empty.";
          });
        }
      }
    });


  }



// Move the email validation function outside _login() so it's reusable
  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+$")
        .hasMatch(email);
  }


  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenCheckTimer?.cancel();
    super.dispose();
  }



  Map<String, String> _errors = {};
  Future<void> _login() async {
    setState(() {
      _errors.clear();
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();

      // Email validation regex pattern
      bool isValidEmail(String email) {
        return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]+").hasMatch(email);
      }

      // Password validation regex pattern for:
      // 1. At least one lowercase letter
      // 2. At least one uppercase letter
      // 3. At least one number
      // 4. At least one special character
      // 5. Minimum length of 8 characters
      bool isValidPassword(String password) {
        return RegExp(r'^(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$').hasMatch(password);
      }

      if (email.isEmpty) {
        _errors['email'] = "Email cannot be empty.";
      } else if (!isValidEmail(email)) {
        _errors['email'] = "Enter a valid email address.";
      }

      if (password.isEmpty) {
        _errors['password'] = "Password cannot be empty.";
      } else if (!isValidPassword(password)) {
        _errors['password'] = "Password Might be wrong";
      }
    });

    if (_errors.isNotEmpty) return;

    // Continue with the login process if no errors
    try {
      String email = _emailController.text.trim();
      String password = _passwordController.text.trim();
      // Make API call
      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Account/Login'),
        body: {
          'Email': email,
          'Password': password,
        },
      );

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token']?['token'] ?? '';
        final role = responseData['role'] ?? ''; // Extract role
        final userId = responseData['id'] ?? ''; // Extract user ID
        final cartId = responseData['cartId'] ?? 0;


        print('Token: $token');
        print('Role: $role');
        print('User ID: $userId');
        print('cart ID: $cartId');

        if (token.isNotEmpty) {
          final expireOn = responseData['token']?['expireon'] ?? '';
          await saveToken(token, expireOn);
          await saveUserId(userId);
          await saveCartId(cartId);

          // Navigate to respective dashboard based on role
          if (role.toLowerCase() == 'user') {
            print('Navigating to BuyerDashboard...');
            _navigateToDashboard(Shops(userId: userId,));
          } else if (role.toLowerCase() == 'owner') {
            print('Navigating to OwnerDashboard...');
            _navigateToDashboard(OwnerDashboard(userId: userId));
          } else {
            _showErrorDialog("Unknown user role.");
          }
        } else {
          _showErrorDialog("No token received. Login failed.");
        }
      } else {
        // Handle non-200 responses
        final responseData = json.decode(response.body);
        final errorMessage = responseData['error'] ?? 'Login failed. Please check your credentials.';
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      // Handle exceptions
      print('Error: $e');
      _showErrorDialog("Email or Password might be wrong.");
    }
  }



// Helper function for navigation
  void _navigateToDashboard(Widget dashboard) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => dashboard),
    );
  }


  Future<void> saveUserId(String id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', id); // Save the 'id' to SharedPreferences
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


  @override
  Widget build(BuildContext context) {
    double height = MediaQuery.of(context).size.height;
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Container(

        width: double.infinity,
        height: double.infinity,

        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/BohoNotMain2.png"),
            alignment: Alignment.centerRight,
            fit: BoxFit.fill,
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add the image
                Padding(
                  padding: const EdgeInsets.only(left: 13.0), // Shift the image to the right by 10px
                  child: Image.asset(
                    "assets/images/BohoMain4.png",
                    width: width * 0.65, // Adjust width as per your design
                    height: height * 0.28, // Adjust height as per your design
                  ),
                ),


                SizedBox(height: 14), // Space between the image and the next widget

                // Email input field
                _buildInputField(width, Icons.email, "Email", _emailController, errorText: _errors['email']),



                SizedBox(height: 4),

                // Password input field
                _buildInputField(width, Icons.lock, "Password", _passwordController, obscureText: true, errorText: _errors['password']),

                SizedBox(height: 2),

                // Forgot Password
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ForgotPassword()),
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.marmelad(
                        fontSize: 15,
                        color: Color((0xFFC39084),),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Log in button
                GestureDetector(
                  onTap: _login,
                  child: Container(
                    height: 60,
                    width: width * 0.7,
                    decoration: BoxDecoration(
                      color: Color(0xFFBD7564),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: Text(
                        'LOG IN',
                        style: GoogleFonts.marmelad(
                          fontSize: 22,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Sign up prompt
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Choosebuyerorowner()),
                    );
                  },
                  child: Text(
                    "Not signed up?",
                    style: GoogleFonts.marmelad(
                      fontSize: 16,
                      color: Color((0xFFC39084),),
                      fontWeight: FontWeight.w500
                    ),
                  ),
                ),



              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(
      double width,
      IconData icon,
      String hintText,
      TextEditingController controller,
      {bool obscureText = false,
        String? errorText}) {
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
              top: 8.88,
              left: 18,
              child: Row(
                children: [
                  Icon(icon, color: Color(0xFFBB7A62)),
                  SizedBox(width: 10),
                  Container(
                    width: width * 0.55,
                    child: TextField(
                      controller: controller,
                      obscureText: obscureText,
                      decoration: InputDecoration(
                        hintText: hintText,
                        hintStyle: TextStyle(color: Color(0xFFBB7A62)),
                        border: InputBorder.none,
                      ),

                      style: TextStyle(fontSize: 16, color: Color(0xFFAF7B66)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (errorText != null) // Show error message if present
          Padding(
            padding: const EdgeInsets.only(left: 18.0, top: 1.0),
            child: Text(
              errorText,
              style: TextStyle(color: Color(0xFFD23420), fontSize: 14),
            ),
          ),
      ],
    );
  }

}
