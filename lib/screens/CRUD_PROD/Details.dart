
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/screens/CRUD_PROD/Product_Additional_Photos.dart';
import 'package:virtual_store/screens/TryOn.dart';
import '../../NavBar.dart';
import '../../constants.dart';
import '../Login.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

class Details extends StatefulWidget {

  final int prodId;
  final String userId;
  Details({required this.prodId,required this.userId});

  @override
  _DetailsState createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  late Future<Map<String, dynamic>> productDetails;
  late Future<List<Map<String, dynamic>>> stockDetails;
  int _selectedIndex = 0;
  int _currentImageIndex = 0;
  List<Map<String, dynamic>> _images = [];
  List<Map<String, dynamic>> availableColors = [];

  bool isLoading = false;
  bool isLoadingSizes = false;
  String? selectedSize;
  String? selectedColor;
  List<Map<String, dynamic>> availableSizes = [];

  TextEditingController quantityController = TextEditingController();
  bool _isButtonVisible = true;
  bool _isAvailableColorsVisible = true;
  bool _isAddToCartVisible = false;
  int userRating = 0;
  bool _hasValidImages = true;

  @override

  void initState() {

    super.initState();
    productDetails = fetchProductDetails(widget.prodId.toString());
    stockDetails = fetchStockDetails(widget.prodId.toString());
    print("This is the product id ${widget.prodId}");
    print('User ID:${widget.userId}');
    fetchUserRating();
    getUserId();
    fetchCartItems();
    // Only call checkSession() on main page, NOT here
  }




  Future<void> fetchUserRating() async {
    final url = Uri.parse('http://vstore.runasp.net/api/User/GetUserRating/${widget.prodId}');
    final String? authToken = await getAuthToken();

    if (widget.userId == null || authToken == null) {
      return;
    }

    try {
      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $authToken",
        },
      );

      if (response.statusCode == 200) {
        final responseBody = response.body;

        if (responseBody.contains("this Product has no Rates yet")) {
          setState(() {
            userRating = 0; // لا يوجد تقييم
          });
        } else {
          // استخراج التقييم من الـ response
          final ratingText = responseBody.replaceAll("Rating is:", "").trim();
          final rating = double.tryParse(ratingText) ?? 0.0;
          setState(() {
            userRating = rating.round(); // تحويل التقييم إلى عدد صحيح
          });
        }
      } else {
        print('Failed to load rating: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching rating: $e');
    }
  }

  Future<void> submitRating(int rating) async {
    final url = Uri.parse('http://vstore.runasp.net/api/User/RateProduct/${widget.prodId}');
    final String? authToken = await getAuthToken();

    if (widget.userId == null || authToken == null) {
      print("Error: User not logged in or userId is missing");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User not logged in or userId is missing")),
      );
      return;
    }

    try {
      print("Preparing request...");
      print("Auth Token: ${authToken.substring(0, min(10, authToken.length))}... (truncated)");
      print("User ID: ${widget.userId}");
      print("Product ID: ${widget.prodId}");
      print("Rating: $rating");

      var request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $authToken'
        ..fields['User_id'] = widget.userId!
        ..fields['Rating'] = rating.toString();

      print("Sending request to: $url");

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 200) {
        setState(() {
          userRating = rating; // تحديث التقييم في الواجهة
        });

        // عرض رسالة الشكر
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return ThankYouDialog(); // استدعاء الويدجت المخصصة
          },
        );
      } else {
        print('Failed to submit rating. Status code: ${response.statusCode}');
        print('Response body: $responseBody');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to submit rating: ${response.statusCode}")),
        );
      }
    } catch (e, stackTrace) {
      print('Exception: $e');
      print('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting rating: $e")),
      );
    }
  }



  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // بنرجع الـ ownerId
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

  Future<void> fetchAvailableColors() async {
    setState(() {
      isLoading = true;
    });

    final url = Uri.parse('http://vstore.runasp.net/api/Cart/AvailableColors/${widget.prodId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> colorsData = json.decode(response.body);
        setState(() {
          availableColors = colorsData.cast<Map<String, dynamic>>();
        });


      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch colors: $e');
    }

    setState(() {
      isLoading = false;
    });
  }


  Future<void> fetchAvailableSizes(String color) async {
    setState(() {
      isLoadingSizes = true;
      selectedSize = null; // Reset selected size when color changes
      availableSizes = [];
    });

    final url = Uri.parse('http://vstore.runasp.net/api/Cart/AvaliabeSizesByColor/${widget.prodId}?ColorId=$color');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> sizesData = json.decode(response.body);
        setState(() {
          availableSizes = sizesData.cast<Map<String, dynamic>>();
        });


      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch sizes: $e');
    }

    setState(() {
      isLoadingSizes = false;
    });
  }




  Future<void> checkSession(BuildContext context) async {
    String? authToken = await getAuthToken();

    if (authToken == null) {
      print("Token is null. Logging out.");
      await saveCartToDatabase(context); // Pass context
      await logout(context);
      return;
    }


    bool expired = await isTokenExpired(authToken);
    print("Token Expired: $expired");

    if (expired) {
      print("Logging out due to expired token.");
      await saveCartToDatabase(context);
      await logout(context);
    } else {
      print("Token is valid.");
    }

  }


  Future<bool> isTokenExpired(String token) async {
    try {
      // Decode JWT token
      Map<String, dynamic> payload = parseJwt(token);
      int? exp = payload["exp"]; // Expiry timestamp

      if (exp == null) return true; // Treat missing expiry as expired

      int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentTimestamp > exp; // Expired if current time > expiry time
    } catch (e) {
      print("Error decoding token: $e");
      return true; // Assume expired on error
    }
  }

// Function to decode JWT token
  Map<String, dynamic> parseJwt(String token) {
    final parts = token.split('.');
    if (parts.length != 3) throw Exception('Invalid token');

    final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    return json.decode(payload);
  }



  Future<void> saveCartToDatabase(BuildContext context) async {
    try {
      String? userId = await getUserId();
      String? authToken = await getAuthToken();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? cartId = prefs.getInt('cartId'); // Get cartId instead of userId

      if (authToken == null || userId == null || cartId == null) {
        print("Error: Missing authentication token, user ID, or cart ID.");
        return;
      }

      // ✅ Check if the token is expired
      if (await isTokenExpired(authToken)) {
        print("Token expired. Logging out...");
        logout(context);
        return;
      }

      List<String> cart = prefs.getStringList('cart_$cartId') ?? []; // Use cartId here

      if (cart.isEmpty) {
        print("No items to save.");
        return;
      }

      for (String item in cart) {
        Map<String, dynamic> cartItem = jsonDecode(item);

        final url = Uri.parse(
            'http://vstore.runasp.net/api/Cart/add-product-to-cart/$userId?Product_id=${cartItem['productid']}&quantity=${cartItem['quantity']}'
        );

        var request = http.MultipartRequest("POST", url)
          ..headers.addAll({
            "Authorization": "Bearer $authToken",
          })
          ..fields['colorid'] = cartItem['color']
          ..fields['sizeid'] = cartItem['size'];

        final response = await request.send();
        final responseBody = await response.stream.bytesToString();

        print('Response Status: ${response.statusCode}');
        print('Response Body: $responseBody');

        if (response.statusCode != 200) {
          print("Failed to save cart item: ${cartItem['productid']}");
        }
      }
      await prefs.remove('cart_$cartId');


      // Clear the cart from the server
      await clearCart(context, authToken);

      // Restore the stored cartId after clearing

      await prefs.remove('cart_$cartId'); // ✅ Clear cart for cartId
      print("Cart successfully saved and cleared.");
    } catch (e) {
      print('Error saving cart to database: $e');
    }
  }



  Future<void> addToCart(BuildContext context) async {
    try {
      String? authToken = await getAuthToken();
      String? userId = await getUserId();
      SharedPreferences prefs = await SharedPreferences.getInstance();

      if (authToken == null || userId == null) {
        print("Error: Missing authentication token or user ID.");
        return;
      }

      if (await isTokenExpired(authToken)) {
        print("Token expired. Logging out...");
        logout(context);
        return;
      }

      if (selectedColor == null || selectedSize == null || quantityController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please select color, size, and enter quantity")),
        );
        return;
      }

      int? quantity = int.tryParse(quantityController.text);
      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please enter a valid quantity.")),
        );
        return;
      }

      int? cartId = prefs.getInt('cartId');
      if (cartId == null) {
        print("❌ No cartId found.");
        return;
      }

      int? storedCartId = cartId;
      print("🆕 Storing cartId before clearing: $storedCartId");

      Map<String, dynamic> product = await fetchProductDetails(widget.prodId.toString());
      String newShopId = (product['shopId'] ?? '').toString();

      List<String> cart = prefs.getStringList('cart_$cartId') ?? [];
      if (cart.isNotEmpty) {
        Map<String, dynamic> firstItem = jsonDecode(cart.first);
        String existingShopId = firstItem['shopId'];

        if (newShopId != existingShopId) {
          bool shouldClearCart = await showClearCartConfirmation(context, authToken, cartId);
          if (!shouldClearCart) return;

          // ✅ Clear local cart after confirmation
          await prefs.remove('cart_$cartId');
          cart = [];
        }
      }

      // ✅ Prevent duplicate item with same productid, color, and size
      bool itemAlreadyExists = cart.any((item) {
        final decoded = jsonDecode(item);
        return decoded['productid'] == widget.prodId.toString()
            && decoded['color'] == selectedColor.toString()
            && decoded['size'] == selectedSize.toString();
      });

      if (itemAlreadyExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("This item with selected color and size is already in the cart.")),
        );
        return;
      }

      final selectedColorName = availableColors
          .firstWhere((color) => color['color_id'].toString() == selectedColor, orElse: () => {})['color_Name'] ?? 'Unknown';

      final selectedSizeName = availableSizes
          .firstWhere((size) => size['size_ID'].toString() == selectedSize, orElse: () => {})['size_Name'] ?? 'Unknown';

      Map<String, dynamic> cartItem = {
        'productid': widget.prodId.toString(),
        'color': selectedColor.toString(),
        'size': selectedSize.toString(),
        'quantity': quantity,
        'productname': product['productName'] ?? 'Unknown',
        'totalprice': (product['product_Price_after_sale'] != null && product['product_Price_after_sale'] != 0)
            ? product['product_Price_after_sale']
            : product['product_Price'],
        'imageBase64': product['defualtimage'] ?? '',
        'shopId': newShopId,
        'size_name': selectedSizeName,
        'color_name': selectedColorName,
      };

      List<String> updatedCart = cart..add(jsonEncode(cartItem));
      await prefs.setStringList('cart_$cartId', updatedCart);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product added to cart successfully!")),
      );
    } catch (e) {
      print('Error: $e');
    }
  }



  Future<bool> showClearCartConfirmation(BuildContext context, String authToken, int cartId) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            "Cart Change Alert",
            style: GoogleFonts.actor(
              color: Color(0xFFC77F6F),
              fontSize: 17,
              fontWeight: FontWeight.w600
        ),
          ),
          content: Text(
            "The old cart items will be DELETED. Do you want to continue?",
            style: TextStyle(color: Color(0xFFC19888), fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                "Cancel",
                style: TextStyle(color: Color(0xFFC77F6F), fontSize: 14),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFD7A08A),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () async {
                await saveCartToDatabase(context);
                Navigator.of(context).pop(true);
              },
              child: Text(
                "Yes",
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }


  Future<Map<String, dynamic>> fetchCartItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? cartId = prefs.getInt('cartId');

      if (cartId == null) {
        print('Error: cartId not found in SharedPreferences');
        return {'cartItems': [], 'totalItems': 0, 'totalPrice': "0.00"};
      }

      print('Fetching cart items for cartId: $cartId');

      // Fetch API items
      final url = Uri.parse('http://vstore.runasp.net/api/Cart/GetCartItemsForUser/$cartId');
      final response = await http.get(url);

      List<Map<String, dynamic>> apiCartItems = [];
      int totalItems = 0;
      double totalPrice = 0.0;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('API Response Data: $data');

        apiCartItems = (data['cartItems'] as List)
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        totalItems = data['totalItems'] ?? 0;
        totalPrice = double.tryParse(data['totalPrice'].toString()) ?? 0.0;
      } else {
        print('Error fetching API cart items: ${response.reasonPhrase}');
      }

      // Fetch Local Items
      List<String> localCartData = prefs.getStringList('cart_$cartId') ?? [];
      List<Map<String, dynamic>> localCartItems = localCartData.map((item) {
        try {
          print('Stored Local Cart Data: $localCartData');

          return Map<String, dynamic>.from(jsonDecode(item) as Map<String, dynamic>);
        } catch (e) {
          print('Error decoding local cart item: $e');
          return <String, dynamic>{};
        }
      }).toList();


      print('Local Cart Items: $localCartItems');

      // Combine API and Local Items
      List<Map<String, dynamic>> combinedCartItems = [...apiCartItems, ...localCartItems];
      totalItems += localCartItems.length;

      print('Final Cart Items: $combinedCartItems');

      return {
        'cartItems': combinedCartItems,
        'totalItems': totalItems,
        'totalPrice': totalPrice.toStringAsFixed(2),

      };
    } catch (e, stacktrace) {
      print('Exception: $e\n$stacktrace');
      return {'cartItems': [], 'totalItems': 0, 'totalPrice': "0.00"};
    }
  }


  Future<void> clearCart(BuildContext context, String authToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int? cartId = prefs.getInt('cartId');

      if (cartId != null) {
        final response = await http.delete(
          Uri.parse('http://vstore.runasp.net/api/Cart/remove-all-products/$cartId'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          print("✅ Cart cleared successfully from server.");
        } else {
          print("❌ Failed to clear cart from server: ${response.statusCode} ${response.body}");
        }
      }

      // Clear cart locally
      for (String key in prefs.getKeys()) {
        if (key.startsWith('cart_')) {
          await prefs.remove(key);
        }
      }

      await prefs.remove('cart_$cartId');
      await prefs.reload();

      print("✅ All local cart data and cartId removed.");
    } catch (e) {
      print("❌ Error in clearCart: $e");
    }
  }




// Modify logout function to call saveCartToDatabase() before logging out
  Future<void> logout(BuildContext context) async {
    try {
      // Save cart items before logging out
      await saveCartToDatabase(context);

      String? authToken = await getAuthToken();
      final prefs = await SharedPreferences.getInstance();

      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Account/Logout'),
        headers: {
          'Content-Type': 'application/json',
          if (authToken != null) 'Authorization': 'Bearer $authToken',
        },
      );

      print("Logout API Response: ${response.statusCode} - ${response.body}");

      // Clear local storage
      await prefs.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.statusCode == 200
            ? "Logged out successfully"
            : "Session expired, logging out")),
      );

      // Navigate to LoginScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } catch (e) {
      print("Error during logout: $e");

      // Ensure user is still logged out even if an error occurs
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Session expired, logging out")),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    }
  }


  //Future<List<Map<String, dynamic>>> getCartItems() async {
  // SharedPreferences prefs = await SharedPreferences.getInstance();
  // List<String>? cartList = prefs.getStringList('cart_items') ?? [];

  //  return cartList.map((item) => jsonDecode(item)).toList();
  //}



  Future<void> removeCartItem(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? cartList = prefs.getStringList('cart_items') ?? [];

    if (index >= 0 && index < cartList.length) {
      cartList.removeAt(index);
      await prefs.setStringList('cart_items', cartList);
    }
  }




// Function to retrieve stored auth token from session
  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the stored session token
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

      List<Map<String, dynamic>> photos = [];

      if (data.containsKey('photos') && data['photos'] is List) {
        photos = List<Map<String, dynamic>>.from(
          data['photos'].map((photo) => {
            'imageId': photo['imageId'] ?? 0,
            'base64Photo': photo['base64Photo']
          }).where((photo) => photo['base64Photo'] is String),
        );
      }

      // Fix typo: "defualtimage" -> "defaultImage"
      String? defaultImage = data.containsKey('defualtimage') ? data['defualtimage'] : null;

      if (defaultImage != null && defaultImage.isNotEmpty) {
        photos.insert(0, {
          'imageId': 0,
          'base64Photo': defaultImage
        });
      }

      setState(() {
        _images = photos;
        _hasValidImages = photos.isNotEmpty;
        if (photos.isNotEmpty) {
          print('Selected Image ID: ${_images[_currentImageIndex]['imageId']}');
        } else {
          print('No images available for this product');
        }
      });

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
        'shopId':data['shopId'],
        'defualtimage':data['defualtimage']
      };
    } else {
      throw Exception('Failed to load product details');
    }
  }




  void _switchImage(int direction) {
    if (_images.isNotEmpty) {
      setState(() {
        _currentImageIndex = (_currentImageIndex + direction) % _images.length;
        if (_currentImageIndex < 0) _currentImageIndex += _images.length;
        print('Selected Image ID: ${_images[_currentImageIndex]['imageId']}');
      });
    }
  }

  void _showTryOnUnavailableDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.95),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFBB7B6C), size: 28),
              SizedBox(width: 10),
              Text(
                "Try-On Unavailable",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFBB7B6C),
                ),
              ),
            ],
          ),
          content: Text(
            "Sorry, virtual try-on is not available for this product or the default image is selected!",
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFBB7B6C),
            ),
            textAlign: TextAlign.left,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFBB7B6C), // Red color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), // Optional: add some padding
              ),
              child: Text(
                "OK",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // White text
                ),
              ),
            ),

          ],
        );
      },
    );
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

              return SingleChildScrollView( // Wrap the Column in a SingleChildScrollView to make the page scrollable
                child: Column(
                  children: [
                    Container(
                      width: screenWidth,
                      height: screenHeight * 0.45,
                      decoration: BoxDecoration(
                        color: Color(0xFFF1E6DF),
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
                                      0xFF967B6B), size: 28),
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
                                      color: Color(
                                          0xFF967B6B)),
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
                              child: Column(
                                children: [
                                  Container(
                                    width: 200,
                                    height: 200,
                                    child: InteractiveViewer(
                                      panEnabled: true,
                                      scaleEnabled: true,
                                      minScale: 1.0,
                                      maxScale: 5.0,
                                      child:  _images.isNotEmpty && decodeBase64Image(_images[_currentImageIndex]['base64Photo']) != null
                                          ? Image.memory(
                                        decodeBase64Image(_images[_currentImageIndex]['base64Photo'])!,
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.cover,
                                      )
                                          : Image.asset(
                                        'assets/images/shirt.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),

                                  ),


                                ],
                              ),
                            ),
                            Positioned(
                              top: screenHeight * 0.29,
                              right: screenWidth * 0.21,
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Color(0xFFF8F3F1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center( // ✅ Center the icon manually
                                  child: GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.transparent,
                                          child: Container(
                                            width: 320,
                                            height: 340,
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Stack(
                                              children: [
                                                // 🔽 Image with zoom
                                                Positioned.fill(
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(10.0),
                                                    child: InteractiveViewer(
                                                      panEnabled: true,
                                                      scaleEnabled: true,
                                                      minScale: 1.0,
                                                      maxScale: 5.0,
                                                      child:  _images.isNotEmpty && decodeBase64Image(_images[_currentImageIndex]['base64Photo']) != null
                                                          ? Image.memory(
                                                        decodeBase64Image(_images[_currentImageIndex]['base64Photo'])!,
                                                        fit: BoxFit.contain,
                                                      )
                                                          : Image.asset(
                                                        'assets/images/shirt.png',
                                                        fit: BoxFit.contain,
                                                      ),
                                                    ),
                                                  ),
                                                ),

                                                // 🔼 Download button on top-right

                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },


                                    child: Icon(Icons.zoom_in, color: Color(
                                        0xFFC7836A), size: 18),
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              bottom: 53,
                              left: 290, // Adjusted to move left
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Stack(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                                        decoration: BoxDecoration(
                                          color: Color(0xFFCE9A86),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Align(
                                          alignment: Alignment.centerLeft, // Moves text to the left
                                          child: Transform.translate(
                                            offset: Offset(-6, -3),
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
                                      // Show original price only if a discount exists
                                      if (data['product_Price_after_sale'] != null &&
                                          data['product_Price'] != null &&
                                          data['product_Price_after_sale'] < data['product_Price'])
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
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.028),
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
                              GestureDetector(
                                onTap: () {
                                  if (_images.isNotEmpty &&
                                      _images[_currentImageIndex]['base64Photo'] != null &&
                                      _images[_currentImageIndex]['imageId'] != 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => TryOnPage(
                                          selectedImage: _images[_currentImageIndex]['base64Photo'],
                                          imageId: _images[_currentImageIndex]['imageId'].toString(),
                                          productName: data['productName'] ?? 'Unknown Product',
                                        ),
                                      ),
                                    );
                                  } else {
                                    _showTryOnUnavailableDialog();
                                  }
                                },
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.accessibility_new, color: Color(0xFFC29785)),
                                    SizedBox(width: 6), // spacing between icon and text
                                    Text(
                                      "Try on",
                                      style: TextStyle(
                                        color: Color(0xFFC29785),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),




                            ],
                          ),

                          SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < 5; i++)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      userRating = i + 1; // تحديث التقييم
                                    });
                                    submitRating(userRating); // إرسال التقييم إلى الـ API
                                  },
                                  child: Icon(
                                    i < userRating ? Icons.star : Icons.star_border,
                                    color: Color(0xFFC99078), // لون النجوم
                                    size: 22,
                                  ),
                                ),
                              SizedBox(width: 74),
                              Row(
                                children: [
                                  Icon(Icons.star, color: Color(0xFFC2917D), size: 18),
                                  SizedBox(width: screenWidth * 0.009),
                                  Text(
                                    "Rate the product",
                                    style: TextStyle(
                                      fontSize: 13,
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
                        buildAttributeBox("Type",  '${data['type'] ?? 'N/A'}', Color(
                            0xFFDEAA8F)),
                        SizedBox(width: 16),
                        buildAttributeBox("Category", '${data['category']?.toString() ?? 'N/A'}', Color(
                            0xFFEEDFD1)),
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




                          if (availableColors.isNotEmpty)

                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text(
                                "Available Colors:",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB0887F)),
                              ),
                            ),
                          isLoading
                              ? Center(child: CircularProgressIndicator())
                              : availableColors.isEmpty
                              ? Center(child: Text(""))
                              : Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            children: availableColors.map((colorMap) {
                              final colorName = colorMap['color_Name'];
                              final colorId = colorMap['color_id'];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedColor = colorId.toString(); // send colorId, not name
                                    fetchAvailableSizes(selectedColor!);
                                  });
                                },
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: selectedColor == colorId.toString()
                                        ? Color(0xFFE2CDBF)
                                        : Color(0xFFF1E6DF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      colorName,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB0887F)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                          ),
                          const SizedBox(height: 10),

                          if (selectedColor != null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Text(
                                "Available Sizes for this color:",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB0887F)),
                              ),
                            ),
                          const SizedBox(height: 10),
                          isLoadingSizes
                              ? Center(child: CircularProgressIndicator())
                              : availableSizes.isEmpty
                              ? SizedBox.shrink()
                              : Wrap(
                            spacing: 15,
                            runSpacing: 10,
                            children: availableSizes.map((sizeMap) {
                              final sizeName = sizeMap['size_Name'];
                              final sizeId = sizeMap['size_ID'];

                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedSize = sizeId.toString(); // Save ID
                                    print('Selected size id: $selectedSize');
                                  });
                                },
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: BoxDecoration(
                                    color: selectedSize == sizeId.toString()
                                        ? Color(0xFFE2CDBF)
                                        : Color(0xFFF1E6DF),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Center(
                                    child: Text(
                                      sizeName,
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB0887F)),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),

                          ),
                          const SizedBox(height: 15),

                          if (selectedSize != null)
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Enter Quantity:",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB0887F)),
                                  ),
                                  const SizedBox(height: 13),
                                  Row(
                                    mainAxisSize: MainAxisSize.min, // Prevents excessive spacing
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.remove_circle, color: Color(0xFF9B7C71)),
                                        onPressed: () {
                                          int currentQuantity = int.tryParse(quantityController.text) ?? 0;
                                          if (currentQuantity > 0) {
                                            quantityController.text = (currentQuantity - 1).toString();
                                          }
                                        },
                                      ),
                                      SizedBox(
                                        width: 60, // Set an exact width for the input field
                                        child: _buildInputField(
                                          width: 86.0, // Match the `SizedBox` width
                                          hintText: '0',
                                          controller: quantityController,
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.add_circle, color: Color(0xFFC0907D)),
                                        onPressed: () {
                                          int currentQuantity = int.tryParse(quantityController.text) ?? 0;
                                          quantityController.text = (currentQuantity + 1).toString();
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),






                          _isAvailableColorsVisible
                              ? ElevatedButton(
                            onPressed: () {
                              fetchAvailableColors();
                              setState(() {
                                _isAvailableColorsVisible = false; // Hide "Available Colors" button
                                _isAddToCartVisible = true; // Show "Add to Cart" button
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDEBFAD), // Button color
                              foregroundColor: Colors.white, // White text color
                              minimumSize: Size(double.infinity, 56), // Full width with height 56
                            ),
                            child: Text(
                              "Available Colors",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          )
                              : SizedBox(), // Empty space when the button is hidden
                          SizedBox(height: 8),

                          _isAddToCartVisible
                              ? ElevatedButton(
                            onPressed: () => addToCart(context), // Use a lambda function to ensure no parameters
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDEBFAD),
                              foregroundColor: Colors.white,
                              minimumSize: Size(double.infinity, 56),
                            ),
                            child: Text(
                              "Add to Cart",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          )
                              : SizedBox(), // Empty space when the button is hidden
                          SizedBox(height: 18),
                        ],

                      ),
                    ),
                  ],
                ),
              );
            }
            return Center(child: Text('No data available'));
          }
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


  Widget _buildInputField({
    required double width,

    required String hintText,
    required TextEditingController controller,

  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: width * 0.69,
          padding: EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/images/InputBorder4_enhanced.png"),
              fit: BoxFit.fill,
            ),
          ),
          child: SizedBox(
            height: 62,
            child: Row(
              children: [


                SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    readOnly: true,
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: TextStyle(color: Color(0xFFC1978C)),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(fontSize: 16, color: Color(0xFFC1978C)), // Text input color set to red

                  ),

                ),
              ],
            ),
          ),
        ),
        // Error message with padding

      ],
    );
  }
}


class ThankYouDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // إغلاق الرسالة بعد 3 ثواني
    Future.delayed(Duration(seconds: 1), () {
      Navigator.of(context).pop(); // إغلاق الرسالة
    });

    return Dialog(
      backgroundColor: Colors.transparent, // خلفية شفافة
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9), // خلفية بيضاء شفافة
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Color(0xFFC19888), // لون الأيقونة
              size: 50,
            ),
            SizedBox(height: 15),
            Text(
              "Thank You!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB0887F), // لون النص
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Your rating has been submitted.",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFFB0887F), // لون النص
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
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

Widget _buildInputField({
  required double width,

  required String hintText,
  required TextEditingController controller,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: width * 0.29,
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/InputBorder4_enhanced.jpg"),
            fit: BoxFit.fill,
          ),
        ),
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              const SizedBox(width: 10),

              SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: TextStyle(color: Color(0xFFC1978C)),
                    border: InputBorder.none,
                  ),
                  style: TextStyle(fontSize: 16, color: Color(0xFFC1978C)),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


