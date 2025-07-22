import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/CRUD_PROD/Create_Stock.dart';  // Import the CreateStockScreen
import 'package:virtual_store/screens/CRUD_PROD/Details.dart';  // تأكد من استيراد Details بشكل صحيح

class ShopProducts extends StatefulWidget {
  final String ShopId;
  final String ShopName;
  final String userId;
  ShopProducts({required this.ShopId, required this.ShopName, required this.userId});

  @override
  _ShopProductsState createState() => _ShopProductsState();
}

class _ShopProductsState extends State<ShopProducts> {
  List<dynamic> products = [];
  bool isLoading = true;
  String searchQuery = "";
  List<Map<String, dynamic>> productsSearch = [];
  List<Map<String, dynamic>> filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
    print("user id : ");
    _printUserId();
    print("this is product id ${widget.ShopId}");
  }

  bool isTokenExpired(String token) {
    return JwtDecoder.isExpired(token);
  }

  Uint8List? decodeBase64Image(String? base64String) {
    if (base64String == null || base64String.isEmpty) {
      return null;
    }
    try {
      return base64.decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }

  Future<void> _printUserId() async {
    final String? UserId = await getUserId();
    if (UserId != null) {
      print('User ID: $UserId');
    } else {
      print('No user ID found');
    }
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');  // Retrieve the OwnerId from shared preferences
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

    if (token == null || isTokenExpired(token)) {
      print('Token is either missing or expired');
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
        Uri.parse("http://vstore.runasp.net/api/User/Get_All_Product/${widget.ShopId}"),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> productData = json.decode(response.body);

        // Fetch ratings for each product
        for (var product in productData) {
          final rating = await fetchProductRating(product['id']);
          product['rating'] = rating;
        }

        setState(() {
          products = productData;
          productsSearch = List.from(products);
          filteredProducts = List.from(products);
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

  Future<double> fetchProductRating(int prodId) async {
    final url = Uri.parse('http://vstore.runasp.net/api/User/GetProductRating/$prodId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseBody = response.body;

        if (responseBody.contains("this Product has no Rates yet")) {
          return 0.0; // No rating available
        } else {
          // Extract the rating from the response
          final ratingText = responseBody.replaceAll("Rating is:", "").trim();
          return double.tryParse(ratingText) ?? 0.0;
        }
      } else {
        print('Failed to load rating: ${response.statusCode}');
        print('Response body: ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('Error fetching rating: $e');
      return 0.0;
    }
  }

  void filterProducts(String query) {
    setState(() {
      searchQuery = query.toLowerCase();

      if (searchQuery.isEmpty) {
        filteredProducts = List.from(products); // Reset to all products if the query is empty
      } else {
        filteredProducts = productsSearch
            .where((product) {
          final productName = product['productName']?.toString().toLowerCase() ?? '';
          print('Checking product: $productName against query: $searchQuery');
          return productName.contains(searchQuery);
        })
            .toList();
      }

      print('Filtered products: $filteredProducts');  // Debugging the filtered products
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 94,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              const SizedBox(width: 7),
              Text(
                'Products',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFE0BBA3),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: TextField(
              onChanged: filterProducts,
              decoration: InputDecoration(
                hintText: 'Search by product name',
                hintStyle: const TextStyle(
                  fontSize: 14.7,
                  color: Color(0xFFD0B3A3),
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFFD0B3A3),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFFC19888), // لون مؤشر التحميل
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchProducts, // تحديث البيانات عند السحب لأسفل
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenHeight * 0.02,
          ),
          child: filteredProducts.isEmpty
              ? Center(
            child: Text(
              'No products available',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[700],
              ),
            ),
          )
              : GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: screenWidth * 0.02,
              mainAxisSpacing: screenHeight * 0.03,
              childAspectRatio: 0.63,
            ),
            itemCount: filteredProducts.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              final decodedImage = decodeBase64Image(product['photo']);
              return GestureDetector(
                onTap: () async {
                  // الانتقال إلى صفحة التفاصيل
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => Details(
                        prodId: product['id'], userId: widget.userId, // تأكد من أن product['id'] موجود
                      ),
                    ),
                  );

                  // إعادة تحميل البيانات بعد العودة
                  setState(() {
                    _fetchProducts(); // إعادة جلب البيانات
                  });
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
                          SizedBox(height: screenHeight * 0.011),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '\$${product['product_Price']}',
                                  style: TextStyle(
                                    color: Colors.brown,
                                    fontSize: screenWidth * 0.038,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    Icons.remove_red_eye_outlined,
                                    color: Colors.grey[700],
                                    size: screenWidth * 0.05,
                                  ),
                                  SizedBox(width: screenWidth * 0.01),
                                  Text(
                                    '${product['product_View']}',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: screenWidth * 0.03,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          // Display the product rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 5; i++)
                                Icon(
                                  i < (product['rating'] ?? 0) ? Icons.star : Icons.star_border,
                                  color: Color(0xFFC19888),
                                  size: 25,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
