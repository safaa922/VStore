import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/CRUD_PROD/Create_Stock.dart';  // Import the CreateStockScreen
import 'package:virtual_store/screens/CRUD_PROD/OwnerProdDetails.dart';
import 'package:virtual_store/screens/CRUD_PROD/ProductDetails.dart';

class Products extends StatefulWidget {
  @override
  _ProductsState createState() => _ProductsState();
}

class _ProductsState extends State<Products> {
  List<dynamic> products = [];
  bool isLoading = true;
  String searchQuery = "";
  List<Map<String, dynamic>> productsSearch = [];
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    _printUserId(); // Call to print user ID
  }

  bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }


  Future<void> _deleteProduct(int productId) async {
    final String? token = await getToken();

    if (token == null) {
      print('No token found, cannot delete product');
      return;
    }

    if (isTokenExpired(token)) {
      print('Token has expired');
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };

    try {
      final response = await http.delete(
        Uri.parse("http://vstore.runasp.net/api/Product/DeleteProduct/$productId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        print('Product deleted successfully');
        _fetchProducts(); // Refresh the product list after deletion
      } else {
        print('Failed to delete product: ${response.body}');
      }
    } catch (e) {
      print('Error deleting product: $e');
    }
  }


  Future<void> _printUserId() async {
    final String? ownerId = await getUserId();
    if (ownerId != null) {
      print('User ID: $ownerId');
    } else {
      print('No user ID found');
    }
  }


  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(
        'id'); // Retrieve the OwnerId from shared preferences
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
    });

    final String? token = await getToken();

    if (token == null) {
      print('No token found, cannot fetch products');
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (isTokenExpired(token)) {
      print('Token has expired');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final headers = {
      'Authorization': 'Bearer $token',
    };

    final String? ownerId = await getUserId();
    if (ownerId == null) {
      print('No ownerId found, cannot fetch products');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
            "http://vstore.runasp.net/api/Product/Get_All_Product/$ownerId"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);

        setState(() {
          products = productData;
          productsSearch = List.from(
              products); // Initialize productsSearch with all products
          filteredProducts =
              List.from(products); // Also populate filteredProducts initially
          isLoading = false;
        });
      } else {
        print('Failed to load products: ${response.body}');
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      setState(() {
        isLoading = false;
      });
    }
  }


  Uint8List? decodeBase64Image(String base64String) {
    try {
      print(
          "Decoding image: $base64String"); // Debugging: Log the base64 string
      return base64.decode(base64String);
    } catch (e) {
      print(
          "Error decoding image: $e"); // Debugging: Log any errors during decoding
      return null;
    }
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      if (searchQuery.isEmpty) {
        filteredProducts =
            List.from(products); // Reset to all products if the query is empty
      } else {
        filteredProducts = productsSearch
            .where((product) {
          final productName = product['productName']
              ?.toString()
              .toLowerCase() ?? '';
          print('Checking product: $productName against query: $searchQuery');
          return productName.contains(searchQuery);
        })
            .toList();
      }

      print(
          'Filtered products: $filteredProducts'); // Debugging the filtered products
    });
  }


  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final screenHeight = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 94,
        // Reduced overall height of the AppBar
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          // Adjust the vertical position of the title and arrow
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.arrow_back_ios_new_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pop(
                      context); // Navigate back to the previous screen
                },
              ),
              const SizedBox(width: 7),
              Text(
                'Products',
                style: const TextStyle(
                  color: Colors.white, // Title color
                  fontSize: 23, // Adjust font size if needed
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFD5B29E),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          // Reduced height of the AppBar's bottom section
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            // Minimized vertical padding
            child: TextField(
              onChanged: filterProducts,
              decoration: InputDecoration(
                hintText: 'Search by product name',
                hintStyle: const TextStyle(
                  fontSize: 14.7, // Set the hint text size smaller
                  color: Color(0xFFD7AF98), // Set the hint text color
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(
                      0xFFD7AF98), // Set the search icon color to match the hint text
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                // Keep padding inside the text field consistent
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView( // Make the body scrollable
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.02,
          vertical: screenHeight * 0.02,
        ),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : (filteredProducts.isEmpty)
            ? Center(child: Text('No products available'))
            : GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: screenWidth * 0.02,
            mainAxisSpacing: screenHeight * 0.03,
            childAspectRatio: 0.6,
          ),
          itemCount: filteredProducts.length,
          // Use filteredProducts.length
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final product = filteredProducts[index]; // Use filteredProducts here
            final decodedImage = decodeBase64Image(product['photo']);
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        OwnerProdDetails(
                          prodId: product['product_Id'],
                        ),
                  ),
                );
              },
              child: Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(screenWidth * 0.02),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF2F1E58).withOpacity(0.2),
                      offset: Offset(0, 3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: decodedImage != null
                                  ? SizedBox(
                                width: double.infinity,
                                height: screenHeight * 0.24,
                                child: Image.memory(
                                  decodedImage,
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.fill,
                                ),
                              )
                                  : Image.asset(
                                'assets/images/Woman.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: screenHeight * 0.25,
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Color(0xFFCC9174),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    '${product['sale_Percentage'] ?? 0}%',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: screenWidth * 0.03,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 5,
                              left: 5,
                              child: Container(
                                width: screenWidth * 0.4,
                                child: Text(
                                  product['productName'],
                                  style: TextStyle(
                                    fontSize: screenWidth * 0.037,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    overflow: TextOverflow.ellipsis,
                                    shadows: [
                                      Shadow(
                                        offset: Offset(0, 2),
                                        blurRadius: 4,
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '\$${product['product_Price']}',
                                style: TextStyle(
                                  color: Color(0xFFBA7F71),
                                  fontSize: screenWidth * 0.039,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                            Row(
                              children: [
                                Icon(
                                  Icons.remove_red_eye_outlined,
                                  color: Color(
                                      0xFFC0B1A9),
                                  size: screenWidth * 0.05,
                                ),
                                SizedBox(width: screenWidth * 0.01),
                                Text(
                                  '${product['product_View']}',
                                  style: TextStyle(
                                    color: Color(
                                        0xFFC0B1A9),
                                    fontSize: screenWidth * 0.036,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.05),
                    Positioned(
                      top:240,
                      bottom: 10,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CreateStockScreen(
                                        productId: product['product_Id'],
                                      ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFC5876E),
                              foregroundColor: Colors.white,
                              minimumSize: Size(37, 37),
                              padding: EdgeInsets.all(4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            child: Icon(
                              Icons.store,
                              size: 17,
                            ),
                          ),
                          SizedBox(width: 4),
                      ElevatedButton(
                        onPressed: () {
                          _deleteProduct(product['product_Id']);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFE3AE92),
                          foregroundColor: Colors.white,
                          minimumSize: Size(37, 37),
                          padding: EdgeInsets.all(4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Icon(
                          Icons.delete,
                          size: 19,
                        ),
                      ),

                      ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      backgroundColor: Colors.white,
    );
  }

}