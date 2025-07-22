import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:virtual_store/constants.dart';

class Products extends StatefulWidget {
  static const String id = 'Products';

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<Products> {
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    try {
      const String apiUrl = 'http://vstore.runasp.net/api/Product/GetAllProducts';
      final response = await Dio().get(apiUrl);

      // Debugging: Print the response data
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;

        setState(() {
          products = data
              .map((product) => {
            'name': product['productName'] ?? 'Unnamed Product',
            'price': product['product_Price'] ?? 0.0,
            'priceAfterSale': product['product_Price_after_sale'] ?? 0.0,
            'material': product['material'] ?? 'Unknown Material',
            'salePercentage': product['sale_Percentage'] ?? 0,
            'photos': product['photos'] ?? [],
          })
              .toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load products. Status code: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      // Debugging: Print the error message
      print('Error occurred: $e');

      setState(() {
        errorMessage = 'Failed to load products. Please try again.';
        isLoading = false;
      });
    }
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final productName = product['name'];
    final productPrice = product['price'];
    final priceAfterSale = product['priceAfterSale'];
    final material = product['material'];
    final salePercentage = product['salePercentage'];
    final photos = product['photos'];

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: photos.isNotEmpty
                ? Image.memory(
              base64.decode(photos[0]), // Assuming first photo is base64 encoded
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Image.asset(
              'assets/images/Placeholder.png',
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  productName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Material: $material',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'Price: \$${productPrice.toString()}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                if (priceAfterSale > 0)
                  Text(
                    'Sale Price: \$${priceAfterSale.toString()}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                if (salePercentage > 0)
                  Text(
                    '$salePercentage% Off',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Colors.brown,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(
        child: Text(
          errorMessage!,
          style: const TextStyle(color: Colors.red),
        ),
      )
          : products.isEmpty
          ? const Center(child: Text('No products found.'))
          : GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate:
        const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 3 / 4,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildProductCard(product);
        },
      ),
    );
  }
}
