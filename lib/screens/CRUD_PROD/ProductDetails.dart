import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProductDetailsScreen extends StatefulWidget {
  final int productId;

  ProductDetailsScreen({required this.productId});

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  bool isLoading = true;
  Map<String, dynamic> productDetails = {};
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchProductDetails();
  }

  Future<void> _fetchProductDetails() async {
    final url = "http://vstore.runasp.net/api/Product/GetProductDetails/${widget.productId}";
    print('Fetching product details from: $url'); // Debugging URL

    try {
      final response = await http.get(Uri.parse(url));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decodedData = json.decode(response.body);
          setState(() {
            productDetails = decodedData;
            isLoading = false;
          });
          print('Product details loaded successfully.');
        } catch (e) {
          setState(() {
            isLoading = false;
            errorMessage = 'Error parsing JSON data';
          });
          print('Error decoding JSON: $e');
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Failed to fetch product. Status code: ${response.statusCode}';
        });
        print('Failed to load product details. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Network error: $e';
      });
      print('Error fetching data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFFC39585), size: 32),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Color(0xFFD1B99C), size: 38),
            onPressed: () {
              // Add your search functionality here
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.06,
          vertical: screenHeight * 0.04,
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : errorMessage.isNotEmpty
            ? Center(
          child: Text(
            errorMessage,
            style: TextStyle(color: Colors.red, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        )
            : productDetails.isEmpty
            ? Center(child: Text('No product details available'))
            : Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              productDetails['productName'] ?? 'N/A',
              style: TextStyle(
                fontSize: screenWidth * 0.05,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              '\$${productDetails['product_Price'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.brown,
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Material: ${productDetails['material'] ?? 'N/A'}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: screenWidth * 0.035,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Sale: ${productDetails['sale_Percentage'] ?? '0'}%',
              style: TextStyle(
                color: Colors.red,
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              'Views: ${productDetails['product_View'] ?? '0'}',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: screenWidth * 0.035,
              ),
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
