import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/screens/ResetPassword.dart';

class CreateStockScreen extends StatefulWidget {
  final int productId;

  CreateStockScreen({required this.productId});

  @override
  _CreateStockScreenState createState() => _CreateStockScreenState();
}
final GlobalKey<FormState> _formKey = GlobalKey<FormState>();


class _CreateStockScreenState extends State<CreateStockScreen> {
  final TextEditingController _quantityController = TextEditingController();
  List<Map<String, dynamic>> _colors = [];
  List<Map<String, dynamic>> _sizes = [];
  String? _selectedColorId;
  String? _selectedSizeId;

  @override
  void initState() {
    super.initState();
    _fetchColors();
    _fetchSizes();
  }


  Future<void> _addColor(String colorName) async {
    final url = Uri.parse('http://vstore.runasp.net/api/Owner/AddColor');

    var request = http.MultipartRequest('POST', url)
      ..fields['Color_Name'] = colorName;

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Color added successfully!')),
        );
        _fetchColors(); // Refresh colors
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add color: ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }

  Future<void> _addSize(String sizeName) async {
    final url = Uri.parse('http://vstore.runasp.net/api/Owner/AddSize');

    var request = http.MultipartRequest('POST', url)
      ..fields['size_Name'] = sizeName;

    try {
      final response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Size added successfully!')),
        );
        _fetchSizes(); // Refresh sizes
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to add size: ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }


  Future<void> _fetchColors() async {
    final url = Uri.parse('http://vstore.runasp.net/api/Owner/GetColors');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _colors = List<Map<String, dynamic>>.from(
            json.decode(response.body).map((color) =>
            {
              'id': color['id'].toString(), // Convert id to String
              'name': color['color_Name'],
            }),
          );
        });
      } else {
        _showSnackbar('Failed to fetch colors.');
      }
    } catch (error) {
      _showSnackbar('Error fetching colors: $error');
    }
  }

  Future<void> _fetchSizes() async {
    final url = Uri.parse('http://vstore.runasp.net/api/Owner/GetSizes');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          _sizes = List<Map<String, dynamic>>.from(
            json.decode(response.body).map((size) =>
            {
              'id': size['id'].toString(), // Convert id to String
              'name': size['size_Name'],
            }),
          );
        });
      } else {
        _showSnackbar('Failed to fetch sizes.');
      }
    } catch (error) {
      _showSnackbar('Error fetching sizes: $error');
    }
  }


  void _showAddDialog({required String type}) {
    final TextEditingController _nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Add New $type',
            style: TextStyle(color: Color(0xFFB0735A), fontSize: 17.7),
          ),
          content: TextField(
            controller: _nameController,
            style: TextStyle(color: Color(0xFFB0735A)), // Red color for user input text
            decoration: InputDecoration(
              labelText: null, // Remove the default label text
              label: Text(
                '$type Name',
                style: TextStyle(color: Color(0xFFBE8A74), fontSize: 14),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color:  Color(0xFFB0735A), width: 1.6), // Red border when not focused
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color:  Color(0xFFB0735A), width: 1.6), // Red border when focused
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFFB0735A))),
            ),
            ElevatedButton(
              onPressed: () {
                if (_nameController.text.isNotEmpty) {
                  if (type == 'Color') {
                    _addColor(_nameController.text);
                  } else {
                    _addSize(_nameController.text);
                  }
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFB0735A),
              ),
              child: Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitStock() async {
    if (_formKey.currentState?.validate() ?? false) {
      final quantity = _quantityController.text;

      print("Selected Color: $_selectedColorId");
      print("Selected Size: $_selectedSizeId");
      print("Quantity: $quantity");

      if (_selectedColorId == null || _selectedSizeId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select a color and size.')),
        );
        return;
      }

      final url = Uri.parse('http://vstore.runasp.net/api/Owner/AddStock');
      try {
        // Create the MultipartRequest
        final request = http.MultipartRequest('POST', url);

        // Add fields
        request.fields['Product_Id'] = widget.productId.toString();
        request.fields['Color_id'] = _selectedColorId.toString();
        request.fields['Size_Id'] = _selectedSizeId.toString();
        request.fields['Quantity'] = quantity;

        // Send the request
        final response = await request.send(); // Changed to send()
        final responseBody = await response.stream
            .bytesToString(); // Get the body as a string
        print("Response Status: ${response.statusCode}");
        print("Response Body: $responseBody");

        // Handle the response
        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Stock added successfully!',  style: TextStyle(color: Color(0xFFB0735A))))
          );
          Navigator.pop(context); // Optionally navigate back
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to add stock , this Stock already exists ',  style: TextStyle(color: Color(0xFFB0735A))))
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields correctly.',  style: TextStyle(color: Color(0xFFB0735A))))
      );
    }
  }


  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:false,
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconBox(),

                SizedBox(height: 14),

                // Use Form widget to group all form fields
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Color Dropdown with custom color scheme and white background for dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedColorId,
                                  items: _colors.map((color) {
                                    return DropdownMenuItem<String>(
                                      value: color['id'],
                                      child: Text(
                                        color['name'],
                                        style: TextStyle(color: Color(0xFFC6947C)), // Set text color to red
                                      ),
                                    );
                                  }).toList(),
                                  decoration: InputDecoration(
                                    labelText: 'Select Color',
                                    labelStyle: TextStyle(color: Color(0xFFC6947C)),
                                    prefixIcon: Icon(Icons.color_lens, color: Color(0xFFC6947C)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFC6947C), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedColorId = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a color' : null,
                                  dropdownColor: Colors.white, // Set dropdown background to white
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, color: Color(0xFFC6947C)),
                                onPressed: () => _showAddDialog(type: 'Color'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 23),

                      // Size Dropdown with custom color scheme and white background for dropdown
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 25),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedSizeId,
                                  items: _sizes.map((size) {
                                    return DropdownMenuItem<String>(
                                      value: size['id'],
                                      child: Text(
                                        size['name'],
                                        style: TextStyle(color: Color(0xFFC6947C)), // Set text color to red
                                      ),
                                    );
                                  }).toList(),
                                  decoration: InputDecoration(
                                    labelText: 'Select Size',
                                    labelStyle: TextStyle(color: Color(0xFFC6947C)),
                                    prefixIcon: Icon(Icons.format_size, color: Color(0xFFC6947C)),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(color: Color(0xFFC6947C), width: 1.5),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedSizeId = value;
                                    });
                                  },
                                  validator: (value) => value == null ? 'Please select a size' : null,
                                  dropdownColor: Colors.white, // Set dropdown background to white
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add, color: Color(0xFFC6947C)),
                                onPressed: () => _showAddDialog(type: 'Size'),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 23),

                      // Quantity Field with custom color scheme
                      Padding(
                        padding: EdgeInsets.only(right: 21),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.574,
                          child: TextFormField(
                            controller: _quantityController,
                            style: TextStyle(color: Color(0xFFC6947C),), // Red color for input text
                            decoration: InputDecoration(
                              labelText: 'Quantity',
                              labelStyle: TextStyle(color: Color(0xFFC6947C)), // Red color for the label
                              prefixIcon: Icon(
                                Icons.production_quantity_limits,
                                color: Color(0xFFC6947C),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color(0xFFC6947C),
                                  width: 1.5,
                                ),
                              ),
                              contentPadding: EdgeInsets.only(bottom: 8),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a quantity';
                              }
                              if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                return 'Quantity must be a positive number';
                              }
                              return null;
                            },
                            keyboardType: TextInputType.number,
                          ),

                        ),
                      ),

                      SizedBox(height: 43),

                      // Add Stock Button with custom color scheme
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.64,
                        child: ElevatedButton(
                          onPressed: _submitStock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC6947C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Add Stock',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 62,
            left: 24,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFC6947C), size: 28),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Text(
                  'Add a Stock',
                  style: TextStyle(
                    color: Color(0xFFC6947C),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


}

  class IconBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Image.asset(
        'assets/images/BoxNew.png',
        width: 240,
        height: 220,
      ),
    );
  }
}

class CustomTextField extends StatelessWidget {
  final String label;
  final IconData icon;
  final TextEditingController controller;

  CustomTextField({
    required this.label,
    required this.icon,
    required this.controller,
  });





  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Color(0xFFA28175)),
        hintText: label,
        hintStyle: TextStyle(color: Color(0xFFA28175)),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFC39585), width: 1.5),
        ),
      ),
    );
  }
}

final headingStyle = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFFC39585));
final subheadingStyle = TextStyle(color: Color(0xFF8E8686), fontSize: 13, fontWeight: FontWeight.bold);
