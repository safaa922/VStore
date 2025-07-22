import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:virtual_store/screens/CRUD_PROD/Product_Additional_Photos.dart';
import 'package:virtual_store/screens/ProductAllPhotos.dart';

import '../../NavBar.dart';
import '../../constants.dart';

class OwnerProdDetails extends StatefulWidget {
  final int prodId;

  OwnerProdDetails({required this.prodId});

  @override
  _OwnerProdDetailsState createState() => _OwnerProdDetailsState();
}

class _OwnerProdDetailsState extends State<OwnerProdDetails> {
  late Future<Map<String, dynamic>> productDetails;
  late Future<List<Map<String, dynamic>>> stockDetails;
  int _selectedIndex = 0;
  int _currentImageIndex = 0;
  List<String> _images = [];

  @override
  void initState() {
    super.initState();
    productDetails = fetchProductDetails(widget.prodId.toString());
    stockDetails = fetchStockDetails(widget.prodId.toString());
  }

  Uint8List? decodeBase64Image(String base64String) {
    try {
      // Remove data URI scheme if present
      if (base64String.contains(',')) {
        base64String = base64String.split(',').last;
      }
      return base64.decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }


  Future<List<Map<String, dynamic>>> fetchStockDetails(String productId) async {
    final response = await http.get(
      Uri.parse('http://vstore.runasp.net/api/Owner/GetAllStock/$productId'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body) as List;
      return data.map((stock) => {
        'color_id': stock['color_id'],
        'size_id': stock['size_ID'],
        'quantity': stock['quantity'],
        'color_Name': stock['color_Name'],
        'size_Name': stock['size_Name'],
      }).toList();
    } else {
      throw Exception('Failed to load stock details');
    }
  }




  Future<Map<String, dynamic>> fetchProductDetails(String productId) async {
    final response = await http.get(
      Uri.parse('http://vstore.runasp.net/api/Product/Get_Product_Details/$productId'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);

      print('API Response: $data'); // Debugging line

      List<String> photos = [];

      if (data.containsKey('photos') && data['photos'] is List) {
        photos = List<String>.from(
          data['photos'].map((photo) => photo['base64Photo']).whereType<String>(), // Extract only base64Photo
        );
      }

      // Fix typo: "defualtimage" -> "defaultImage"
      String? defaultImage = data.containsKey('defualtimage') ? data['defualtimage'] : null;

      if (defaultImage != null && defaultImage.isNotEmpty) {
        photos.insert(0, defaultImage);
      }

      return {
        'photos': photos,
        'product_Price': data['product_Price'] ?? '0',
        'product_Price_after_sale': data['product_Price_after_sale'] ?? '0',
        'product_View': data['product_View'] ?? '0',
        'productName': data['productName'] ?? 'Unknown Product',
        'sale_Percentage': data['sale_Percentage'] ?? 0,
        'material': data['material'] ?? 'Unknown Material',
        'type': data['type'] ?? 'Unknown type',
        'category_Id': data['category_Id'] ?? '0',
        'category': data['category'] ?? 'None',
        'category_Name': data['category_Name'] ?? 'None',
        'description': data['description'] ?? 'Unknown description',
      };
    } else {
      throw Exception('Failed to load product details');
    }
  }




  void _switchImage(int direction) {
    if (_images.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + direction) % _images.length;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<Map<String, dynamic>>(
        future: productDetails,
        builder: (context, snapshot) {
          print("API Response: ${json.encode(snapshot.data)}");

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final data = snapshot.data!;
            final photos = data['photos'] as List<dynamic>? ?? [];
            _images = photos.map((photo) => photo.toString()).toList();

            return SingleChildScrollView( // Wrap the Column in a SingleChildScrollView to make the page scrollable
              child: Column(
                children: [
                  Container(
                    width: screenWidth,
                    height: screenHeight * 0.45,
                    decoration: BoxDecoration(
                      color: Color(0xFFF3E4DA),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(100),
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 42),
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(CupertinoIcons.left_chevron, color: Color(
                                    0xFF9B7D5C), size: 28),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                              SizedBox(width: 3),
                              Text(
                                "Product Details",
                                style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF9B7D5C)),
                              ),
                            ],
                          ),
                          Positioned(
                            top: 63,
                            left: 26,
                            child: Container(
                              padding: EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Color(0xFFC28973),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${data['sale_Percentage']?.toString() ?? '0'}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,

                                ),
                              ),
                            ),
                          ),


                          Positioned(
                            top: 239,
                            left: 27,
                            child: Container(
                              width: 38, // Adjust width to make the square smaller
                              height: 38, // Adjust height to make the square smaller
                              decoration: BoxDecoration(
                                color: Color(0xFFD5A68C),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center( // Ensures the icon stays centered
                                child: IconButton(
                                  icon: Icon(Icons.add_a_photo, size: 19, color: Colors.white),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => Product_Additional_Photos(Prod_id: widget.prodId),
                                      ),
                                    );
                                  },
                                  padding: EdgeInsets.zero, // Removes default padding
                                  constraints: BoxConstraints(), // Prevents IconButton from expanding
                                ),
                              ),
                            ),
                          ),





                          Positioned(
                            top: screenHeight * 0.16,
                            left: 0,
                            child: IconButton(
                              icon: Icon(Icons.arrow_back_ios, size: 32, color: Colors.white),
                              onPressed: () {
                                _switchImage(-1);
                              },
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 0.16,
                            right: 0,
                            child: IconButton(
                              icon: Icon(Icons.arrow_forward_ios, size: 32, color: Colors.white),
                              onPressed: () {
                                _switchImage(1);
                              },
                            ),
                          ),
                          Positioned(
                            top: screenHeight * 0.1,
                            left: (screenWidth - 230) / 2,
                            child: Stack(
                              children: [
                                _images.isNotEmpty && decodeBase64Image(_images[_currentImageIndex]) != null
                                    ? Image.memory(
                                  decodeBase64Image(_images[_currentImageIndex])!,
                                  width: 200,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                                    : Image.asset(
                                  'assets/images/shirt.png',  // Default placeholder image
                                  width: 190,
                                  height: 190,
                                  fit: BoxFit.cover,
                                ),


                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 53,
                            left: 287, // Adjusted to move left
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Stack(
                                  children: [
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFCE9A86),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerLeft, // Moves text to the left
                                        child: Transform.translate(
                                          offset: Offset(-3, -3),
                                          child: Text(
                                            '\$${data['product_Price_after_sale']?.toString() ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13.7,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),


                                    ),
                                    Positioned(
                                      top: 25,
                                      left: 24, // Position of the original price
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Text(
                                            '\$${data['product_Price']?.toString() ?? 'N/A'}',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Transform.rotate(
                                            angle: -0.2, // Adjust the angle for slant (negative for left tilt, positive for right)
                                            child: Container(
                                              width: 34, // Adjust length to fit text
                                              height: 1, // Thickness of the line
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  ],
                                ),
                                SizedBox(height: 5),
                              ],
                            ),
                          ),


                          Positioned(
                            bottom: 0,
                            left: 310,
                            child: Container(
                              padding: EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Color(
                                    0xFFBEB3AD)),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.remove_red_eye, color: Color(
                                      0xFFBEB3AD), size: 16),
                                  Text('${data['product_View']?.toString() ?? 'N/A'}',
                                      style: TextStyle(
                                          color: Color(
                                              0xFFBEB3AD),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800)),
                                ],
                              ),
                            ),
                          ),


                          Positioned(
                            top: 239,
                            left: 239,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: BoxDecoration(
                                color: Color(0xFFF8F3F1), // Transparent background
                                shape: BoxShape.circle,
                                // Optional: match your theme
                              ),
                              child: Center(
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductAllPhotos(prodId: widget.prodId),
                                      ),
                                    );
                                  },
                                  child: Icon(
                                    Icons.swap_horiz,
                                    color: Color(0xFFC7836A), // Match your theme color
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),



                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.017),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 42),
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${data['productName']}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC29785),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit, color: Color(0xFFC49C8C)), // Pen icon
                              onPressed: () {
                                // Add your edit functionality here
                              },
                            ),
                          ],
                        ),

                        SizedBox(height: 17),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            for (int i = 0; i < 5; i++)
                              Icon(
                                i < 4 ? Icons.star : Icons.star_border,
                                color: Color(0xFFC99078),
                                size: 22,
                              ),
                            SizedBox(width: 72),
                            Row(
                              children: [
                                Icon(Icons.star, color: Color(0xFFC29785), size: 20),
                                SizedBox(width: screenWidth * 0.009),
                                Text(
                                  "User avg rates",
                                  style: TextStyle(
                                    fontSize: 13.6,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC29785),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.035),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildAttributeBox("Material",  '${data['material'] ?? 'N/A'}', Color(0xFFC38675)),
                      SizedBox(width: 16),
                      buildAttributeBox("Type",  '${data['type'] ?? 'N/A'}', Color(0xFFDEAA8F)),
                      SizedBox(width: 16),
                      buildAttributeBox("Category", '${data['category']?.toString() ?? 'N/A'}', Color(0xFFEEDFD1)),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.039),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 45),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Description",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC29785),
                          ),
                        ),
                        SizedBox(height: 18),
                        Text(

                          '${data['description']?.toString() ?? 'N/A'}',
                          style: TextStyle(color: Color(0xFFC29785),fontWeight: FontWeight.w400),
                        ),


                        SizedBox(height: 39),
                        Text(
                          "Stocks",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFC19888),
                          ),
                        ),
                        SizedBox(height: 20),
                        FutureBuilder<List<Map<String, dynamic>>>(
                          future: stockDetails, // Fetch stock details
                          builder: (context, stockSnapshot) {
                            if (stockSnapshot.connectionState == ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            } else if (stockSnapshot.hasError) {
                              return Center(child: Text('No Stocks Available',style: TextStyle(color: Color(0xFFB0735A),fontWeight: FontWeight.w500)));
                            } else if (stockSnapshot.hasData) {
                              final stocks = stockSnapshot.data!;
                              return Column(
                                children: stocks.map((stock) {
                                  return buildSizeBox(
                                    stock['color_Name'].toString(),
                                    stock['size_Name'].toString(),
                                    stock['quantity'].toString(),
                                    screenWidth,
                                  );
                                }).toList(),
                              );
                            } else {
                              return Center(child: Text('No stock data available',style: TextStyle(color: Color(0xFFB0735A))));
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          } else {
            return Center(child: Text('No data available'));
          }
        },
      ),
    );
  }


  Widget buildAttributeBox(String title, String value, Color color) {

    return Container(
      padding: EdgeInsets.symmetric(vertical: 17, horizontal: 23),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSizeBox(String color, String size, String quantity, double screenWidth) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      width: screenWidth - 60,
      padding: EdgeInsets.symmetric(vertical: 20, horizontal: 22),
      decoration: BoxDecoration(
        color: Color(0xFFFAF2EA),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.color_lens, color: Color(0xFFBE9076), size: 18),
                  SizedBox(width: 5),
                  Text(
                    "Color: $color",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFBE9076)),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Row(
                children: [
                  Icon(Icons.straighten, color: Color(0xFFBE9076), size: 18),
                  SizedBox(width: 5),
                  Text(
                    "Size: $size",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFBE9076)),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.inventory_2, color: Color(0xFFBE9076), size: 14),
              SizedBox(width: 5),
              Text(
                "Quantity: $quantity",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(
                    0xFFBE9076)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
