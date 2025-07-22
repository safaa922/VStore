import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';  // For File
import 'package:virtual_store/constants.dart';

class CreateCategoryScreen extends StatefulWidget {
  @override
  _CreateCategoryScreenState createState() => _CreateCategoryScreenState();
}

class _CreateCategoryScreenState extends State<CreateCategoryScreen> {
  int _selectedIndex = 0;
  final TextEditingController _categoryTitleController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _categoryError;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
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
  // Function to call the API
  Future<void> _createCategory() async {
    final categoryTitle = _categoryTitleController.text;

    // Ensure the category title is not empty
    if (_formKey.currentState!.validate()) {
      try {
        var uri = Uri.parse('http://vstore.runasp.net/api/Owner/AddCategory');
        var request = http.MultipartRequest('POST', uri);

        // Add the category title to the form data
        request.fields['Category_name'] = categoryTitle;

        var response = await request.send();

        if (response.statusCode == 200) {
          // Show success dialog
          _showDialog('Success', 'Category created successfully!');
        } else {
          _showDialog('Error', 'Failed to create category. Please try again.');
        }
      } catch (e) {
        _showDialog('Error', "Error: $e");
      }
    }
  }

  // Helper function to show a dialog message
  void _showDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Optionally, navigate to another page after success
                if (title == 'Success') {
                  Navigator.pop(context);  // Close the CreateCategory screen
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Helper function to show a snackbar message
  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Validation for category title (only allows alphabets)
// Validation for category title (allows alphabets, spaces, and punctuation)
  String? _validateCategoryTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a category title.';
    }
    final RegExp regex = RegExp(r'^[a-zA-Z0-9\s.,?!-]+$');  // Allows alphabets, numbers, spaces, and punctuation
    if (!regex.hasMatch(value)) {
      return 'Category title must contain only letters, numbers, spaces, and punctuation (.,?!-).';
    }
    return null;
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double padding = screenWidth * 0.1; // 10% of screen width for padding
    double imageSize = screenHeight * 0.43; // 30% of screen height for the image size

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Image Section
          Stack(
            children: [
              Image.asset(
                'assets/images/ShoppingEdit6.png',
                fit: BoxFit.cover,
                width: double.infinity, // Ensures the image takes the full width
                height: imageSize, // Dynamically setting the height based on screen height
              ),
              Positioned(
                top: 20, // Adjust the position as needed
                left: 20, // Adjust the position as needed
                child: IconButton(
                  icon: Icon(CupertinoIcons.left_chevron,
                      color: Color(0xFFC39585), size: 32),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),

          SizedBox(height: 40),

          // Title Section
          Text(
            'Create a Category',
            style: TextStyle(
              fontSize: screenWidth * 0.06, // Adjust font size relative to screen width
              fontWeight: FontWeight.bold,
              color: K_black2,
            ),
          ),

          SizedBox(height: 30),

          // Category Title Input Field
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.173),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _categoryTitleController,
                    decoration: InputDecoration(
                      labelText: 'Category Title',
                      labelStyle: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: Biege3,
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Biege3, width: 2.0),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Biege3, width: 2.0),
                      ),
                      prefixIcon: Icon(Icons.category, color: Biege3),
                    ),
                    validator: _validateCategoryTitle,
                  ),
                  if (_categoryError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _categoryError!,
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: 50),

          // Create Button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: K_black2, // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.27, vertical: 15),
            ),
            onPressed: _createCategory,
            child: Text(
              'Create',
              style: TextStyle(
                color: Colors.white,
                fontSize: 23,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(35),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0.1),
        decoration: BoxDecoration(
          color: Biege3,
          borderRadius: BorderRadius.circular(46),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: _buildNavBarIcon(Icons.home, _selectedIndex == 0),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBarIcon(Icons.notifications, _selectedIndex == 1),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBarIcon(Icons.create, _selectedIndex == 2),
              label: '',
            ),
            BottomNavigationBarItem(
              icon: _buildNavBarIcon(Icons.person, _selectedIndex == 3),
              label: '',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          iconSize: 24, // Adjusted icon size
        ),
      ),
    );
  }
}
