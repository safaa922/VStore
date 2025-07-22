import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/screens/CRUD_PROD/CreateCategory.dart';
import 'package:virtual_store/screens/CRUD_PROD/Create_Prod.dart';
import 'package:virtual_store/screens/CRUD_PROD/Products.dart';
import 'package:http/http.dart' as http;
import 'package:virtual_store/screens/LocationUpdate.dart';
import 'package:virtual_store/screens/OwnerProfile.dart';
import 'dart:convert';
import 'package:virtual_store/screens/CRUD_PROD/Create_Stock.dart';
import 'package:virtual_store/screens/Notification.dart';
import 'CRUD_PROD/OwnerStatistics.dart';
import 'Login.dart';
import 'package:virtual_store/NavBar.dart';
import 'package:virtual_store/screens/CRUD_PROD/Details.dart';



class OwnerDashboard extends StatefulWidget {
  static String id = 'OwnerDashboard';
  final String userId;

  OwnerDashboard({required this.userId});
  @override
  _OwnerDashboardState createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // بنرجع الـ ownerId
  }

  Future<void> _onItemTapped(int index) async {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // الانتقال للـ OwnerDashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OwnerDashboard(userId: widget.userId,)),
      );
    } else if (index == 2) {
      String? userId = await getUserId();
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Notificationsuser(userId: userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No user ID found. Please log in.")),
        );
      }
    } else if (index == 3) {
      String? ownerId = await getUserId();
      if (ownerId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => OwnerProfile(ownerId: ownerId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No owner ID found. Please log in.")),
        );
      }
    }
  }

  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the stored session token
  }


  Future<void> saveCartToDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> cartList = prefs.getStringList('cartItems') ?? [];

      if (cartList.isEmpty) return; // No items to save

      String? authToken = await getAuthToken();

      for (String item in cartList) {
        Map<String, dynamic> cartItem = jsonDecode(item);

        final url = Uri.parse(
            'http://vstore.runasp.net/api/Cart/add-product-to-cart/${cartItem['userId']}?Product_id=${cartItem['productId']}&quantity=${cartItem['quantity']}'
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
          print("Saved cart item to database: ${cartItem['productId']}");
        } else if (response.statusCode == 401) {
          print("Token expired, logging out...");

          // Call token expiration handler
          await handleTokenExpiration();
          return;
        } else {
          print("Failed to save cart item: $responseBody");
        }
      }

      // Clear cart after saving to the database
      await prefs.remove('cartItems');
    } catch (e) {
      print('Error saving cart to database: $e');
    }
  }



  Future<void> logout() async {
    try {
      // Save cart items to the database before logging out
      await saveCartToDatabase();

      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Account/Logout'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear(); // Clear local storage

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Logged out successfully")),
        );

        // Navigate to the LoginScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to log out")),
        );
      }
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  Future<void> handleTokenExpiration() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear stored token and user data

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Session expired. Please log in again.")),
    );

    // Navigate back to the login screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }




  Widget _buildNavBarIcon(IconData iconData, bool isSelected) {
    return isSelected
        ? Container(
      padding: EdgeInsets.all(1),
      decoration: BoxDecoration(
        shape: BoxShape.circle,

        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.3),
            blurRadius: 10.0,
            spreadRadius: 2.0,
            offset: Offset(0, 0),
          ),
        ],
      ),
      child: Icon(iconData, color: Colors.white, size: 29),
    )
        : Icon(iconData, color: Colors.white, size: 29);
  }


  Widget _buildSquare(String label, Color bgColor, IconData iconData, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 120,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(iconData, color: Colors.white, size: 20),
            SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(fontSize: 15, color: Colors.white),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              padding: EdgeInsets.only(top: 20, right: 22, left: 22),
              icon: Icon(Icons.menu, color: Color(0xFFD0A990), size: 38),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),
        actions: [

        ],
      ),
      drawer: Container(
        width: MediaQuery.of(context).size.width * 0.53,
        color: Color(0xFFE4D1C2),
        child: ListView(
          padding: EdgeInsets.only(top: 360, right: 10, left: 10),
          children: [

            ListTile(
              leading: Icon(Icons.logout, size: 30, color: Colors.white),
              title: Text(
                'Log Out',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onTap: () {
                logout(); // Call the logout method
                Navigator.pop(context); // Close the drawer
              },
            ),

            ListTile(
              leading: Icon(Icons.location_pin, size: 30, color: Colors.white),
              title: Text(
                'GPS',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LocationUpdateScreen(userId: widget.userId)),
                );
              },
            ),
          ],
        ),
      ),



      body: Column(
        children: [

          SizedBox(height: 75),

          // Text Section

          Align(
            alignment: Alignment.centerLeft, // Align to the left
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 44), // Adjust horizontal padding
              child: Text(
                "What's On Your Mind?",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFB0715F),
                ),
              ),
            ),
          ),


          SizedBox(height: 33),

          // Image Section with Rounded Corners
          Center(
            child: Container(
              width: 316,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15), // Rounded corners

              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.asset(
                  'assets/images/Welcome.png',
                  width: 300,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          SizedBox(height: 40),

          // Squares Section
          Center(
            child: Container(
              width: 320,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSquare(
                        'Add a\n Product',
                        Color(0xFFB0715F),
                        Icons.add_shopping_cart,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>CreateProd(userId: widget.userId) ),
                          );
                        },
                      ),
                      _buildSquare(
                        'My Products',
                        Color(0xFFDFB7A1),
                        Icons.category,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => Products()),
                          );
                        },
                      ),


                      _buildSquare(
                        'Statistics',
                        Color(0xFFEFE1D3),
                        Icons.list_alt,
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => OwnerStatisticsScreen(ownerId: widget.userId,)),
                          );
                          // Add navigation logic here if needed
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, userId: widget.userId,

      ),
    );
  }
}