import 'package:flutter/material.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/NavBarUser.dart';
import 'package:virtual_store/screens/Shops.dart';
import 'package:virtual_store/NavBar.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:http/http.dart' as http;


class BuyerDashboard extends StatefulWidget {
  static String id = 'BuyerDashboard';

  @override
  _BuyerDashboardState createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;



  Future<void> logout() async {
    final response = await http.post(
      Uri.parse('http://vstore.runasp.net/api/Account/Logout'),
      headers: {
        'Content-Type': 'application/json',
        // Add any necessary headers like authorization token here, if needed
      },
    );

    if (response.statusCode == 200) {
      // If the server returns a 200 OK response, log the user out
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Logged out successfully")));

      // Navigate to the LoginScreen after successful logout
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()), // Navigates directly to LoginScreen
      );
    } else {
      // If the server returns an error
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to log out")));
    }
  }


  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to BuyerDashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BuyerDashboard()),
      );
    } else if (index == 1) {
      // Navigate to Shops
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Shops(userId: LoginScreen.id,)),
      );
    }
  }





  Widget _buildNavBarIcon(IconData iconData, bool isSelected) {
    return isSelected
        ? Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [BiegeLight, BiegeDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Icon(iconData, color: Colors.white, size: 33),
    )
        : Icon(iconData, color: Colors.white, size: 33);
  }

  Widget _buildCategoryIcon(IconData iconData, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: BiegeLight3, // Set background color for category icons
          ),
          child: Icon(iconData, color: Colors.white, size: 28), // Set icon color to white
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 14, color: K_black),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the main background color here
      appBar: AppBar(
        backgroundColor: Colors.white, // Consistent app bar color
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              padding: EdgeInsets.only(top: 20, right: 22, left: 22),
              icon: Icon(Icons.menu, color: Biege2, size: 38),
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
        color: BiegeLight3,
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
                logout(); // Call the logout method when the user taps the logout option
                Navigator.pop(context); // Close the drawer
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 90),
          // Image section
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/Collection3.jpg',
                fit: BoxFit.cover,
                width: 340,
                height: 100,
              ),
            ),
          ),
          SizedBox(height: 40),
          // Category section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 39.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCategoryIcon(Icons.woman, 'Women'),
                _buildCategoryIcon(Icons.man, 'Men'),
                _buildCategoryIcon(Icons.child_care, 'Children'),
                _buildCategoryIcon(Icons.select_all, 'All'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavBarUser(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped, userId: LoginScreen.id,
      ),

    );
  }
}
