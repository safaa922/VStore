import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts package
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/NavBar.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/screens/NavBarUser.dart';
import 'package:virtual_store/screens/Notification.dart';
import 'package:virtual_store/screens/Shops.dart';
import 'package:virtual_store/screens/UserProfile.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;


class Cart_Items extends StatefulWidget {
  @override
  _Cart_ItemsState createState() => _Cart_ItemsState();
}

class _Cart_ItemsState extends State<Cart_Items> {
  int _selectedIndex = 1;
  bool _isLoading = false;
  String? _responseMessage;

  List<String> availableColors = [];
  bool isLoading = false;
  bool isLoadingSizes = false;
  String? selectedSize;
  String? selectedColor;
  List<String> availableSizes = [];
  TextEditingController quantityController = TextEditingController();
  bool _isButtonVisible = true;
  bool _isAvailableColorsVisible = true;
  bool _isAddToCartVisible = false;
  int userRating = 0;


  late Future<Map<String, dynamic>> cartData = Future.value({
    "cartItems": [],
    "totalItems": 0,
    "totalPrice": "0.00",
  });

  @override
  void initState() {
    super.initState();

    fetchLatestCartData();
  }

  void fetchLatestCartData() {
    setState(() {

      cartData = fetchCartItems();
    });
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

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }



// Function to retrieve stored auth token from session
  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the stored session token
  }

  Future<void> updateQuantity(String productId, int delta) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? cartId = prefs.getInt('cartId');
    if (cartId == null) return;

    List<String> cart = prefs.getStringList('cart_$cartId') ?? [];
    List<String> updatedCart = [];

    for (String itemJson in cart) {
      Map<String, dynamic> cartItem = jsonDecode(itemJson);
      if (cartItem['productid'].toString() == productId) {
        int quantity = cartItem['quantity'] ?? 1;
        final unitPrice = double.tryParse(cartItem['unitPrice'].toString()) ?? 0.0;

        quantity += delta;
        if (quantity <= 0) continue;

        cartItem['quantity'] = quantity;
        cartItem['totalPrice'] = (unitPrice * quantity).toStringAsFixed(2);
      }
      updatedCart.add(jsonEncode(cartItem));
    }

    await prefs.setStringList('cart_$cartId', updatedCart);

    // 🔄 Refresh UI by calling setState and refetching cart data
    setState(() {
      cartData = fetchCartItems(); // This must be a synchronous getter or future-handled
    });
  }


  void _showPaymentDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 280,  // 👈 Increase width
            height: 160, // 👈 Increase height
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: EdgeInsets.only(top:20,bottom: 7,left: 23,right: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Choose Payment Method",
                  style: TextStyle(
                    color: Color(0xFFC98D77),
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          createOrder("Cash");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC98D77),
                          padding: EdgeInsets.symmetric(vertical: 9, horizontal: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Cash",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.monetization_on_outlined, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    SizedBox(
                      width: 110,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          createOrder("OnlinePayment");
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFC98D77),
                          padding: EdgeInsets.symmetric(vertical: 9, horizontal: 7),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Visa",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(width: 4),
                            Icon(Icons.credit_card, color: Colors.white, size: 18),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Spacer(),
              ],
            ),
          ),
        );
      },
    );
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

      await prefs.remove('cart_$cartId'); // ✅ Clear cart for cartId
      print("Cart successfully saved and cleared.");
    } catch (e) {
      print('Error saving cart to database: $e');
    }
  }





  Future<void> createOrder(String paymentMethod) async {
    final userId = await getUserId();
    await saveCartToDatabase(context);
    if (userId == null || userId.isEmpty) {
      print("Error: User ID is null or empty.");
      setState(() {
        _responseMessage = "Error: User ID not found. Please log in.";
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _responseMessage = null;
    });

    final url = Uri.parse("http://vstore.runasp.net/api/Order/create-order/$userId");
    print("Attempting to create order for user: $userId");
    print("POST Request URL: $url");

    final body = jsonEncode({
      "paymentMethod": paymentMethod,
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      print("Response Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");

      setState(() {
        if (response.statusCode == 200) {
          _responseMessage = "Order created successfully!";
          print("Order created successfully.");
        } else {
          _responseMessage = "Failed to create order: ${response.body}";
          print("Error creating order: ${response.body}");
        }
      });
    } catch (e, stacktrace) {
      print("Exception occurred: $e");
      print("Stack Trace: $stacktrace");

      setState(() {
        _responseMessage = "Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }




  Future<void> removeCartItem(BuildContext context, String productId) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      int? cartId = prefs.getInt('cartId');
      String? authToken = await getAuthToken();
      String? userId = await getUserId();

      if (cartId == null || authToken == null || userId == null) {
        print('❌ Error: Missing cartId, auth token, or userId.');
        return;
      }

      List<String> localCartData = prefs.getStringList('cart_$cartId') ?? [];
      print('📦 Local Cart Raw Data: $localCartData');

      bool foundInLocal = false;
      List<String> updatedCart = [];

      for (String item in localCartData) {
        Map<String, dynamic> cartItem = jsonDecode(item);
        print('🔍 Decoded cart item: $cartItem');

        final itemId = cartItem['productid']?.toString(); // Safely access it
        print('🆔 Comparing: $itemId vs $productId');

        if (itemId != productId) {
          updatedCart.add(item);
        } else {
          foundInLocal = true;
        }
      }

      if (foundInLocal) {
        await prefs.setStringList('cart_$cartId', updatedCart);
        print('✅ Item removed from local cart.');
      } else {
        // Not found locally, try removing via API
        try {
          final url = Uri.parse(
            'http://vstore.runasp.net/api/Cart/remove-product-from-cart/$userId?Product_id=$productId',
          );

          final response = await http.delete(
            url,
            headers: {
              'Authorization': 'Bearer $authToken',
              'Content-Type': 'application/json',
            },
          );

          print('🛰️ API Response Code: ${response.statusCode}');
          print('🛰️ API Response Body: ${response.body}');

          if (response.statusCode != 200) {
            throw Exception('Failed to remove item via API.');
          } else {
            print('✅ Item removed from server cart.');
          }
        } catch (e) {
          print('❌ API error while removing item: $e');
        }
      }

      // 🌀 Refresh UI/cart data after removal
      setState(() {
        cartData = fetchCartItems(); // or your actual method
      });

      print('🔄 Cart refreshed.');
    } catch (e) {
      print('❌ Unexpected error in removeCartItem: $e');
    }
  }



  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id') ?? ''; // Return an empty string if null
  }


  Future<Map<String, dynamic>> fetchCartItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.reload();
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

        // Use 'priceAfterSelling' for API items instead of 'totalprice'
        for (var item in apiCartItems) {
          double price = double.tryParse(item['priceAfterSelling'].toString()) ?? 0.0;
          int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
          totalPrice += price * quantity;
        }
      } else {
        print('Error fetching API cart items: ${response.reasonPhrase}');
      }

      // Fetch Local Items
      List<String> localCartData = prefs.getStringList('cart_$cartId') ?? [];
      List<Map<String, dynamic>> localCartItems = localCartData.map((item) {
        try {
          return Map<String, dynamic>.from(jsonDecode(item) as Map<String, dynamic>);
        } catch (e) {
          print('Error decoding local cart item: $e');
          return <String, dynamic>{};
        }
      }).toList();

      print('Local Cart Items: $localCartItems');

      // Calculate total price from local items
      double localTotalPrice = 0.0;
      for (var item in localCartItems) {
        item['isLocal'] = true;

        double price = double.tryParse(item['totalprice'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['quantity'].toString()) ?? 1;
        localTotalPrice += price * quantity;
      }

      // Combine all items
      List<Map<String, dynamic>> combinedCartItems = [...apiCartItems, ...localCartItems];
      totalItems += localCartItems.length;
      totalPrice += localTotalPrice;

      print('Final Cart Items: $combinedCartItems');
      print('Final Total Price (API + Local): $totalPrice');

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


  Uint8List? decodeBase64Image(String base64String) {
    try {
      print("Decoding image: $base64String");
      return base64.decode(base64String);
    } catch (e) {
      print("Error decoding image: $e");
      return null;
    }
  }



  Future<void> _onItemTapped(int index) async {
    print(
        'Tapped index: $index'); // Debugging: check if the correct index is tapped.

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      print("Navigating to BuyerDashboard");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Shops(userId: LoginScreen.id,)),
      );
    }

    else if (index == 1) {
      print("Navigating to Cart");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Cart_Items()),
      );
    }
    else if (index == 2) {
      String? userId = await getUserId();
      print("Navigating to Notificationsuser");
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Notificationsuser(userId: userId)),
        );
      }}

    else if (index == 3) {
      String? userId = await getUserId();
      // Navigate to Shops
      print("Navigating to Profile");
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProfile(userId: userId)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No owner ID found. Please log in.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        toolbarHeight: 90,
        leading: SizedBox(), // Removes the back arrow
        title: Padding(
          padding: EdgeInsets.only(right: 13, top: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Your Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 21,
                ),
              ),
              SizedBox(width: 12),
              Icon(
                Icons.shopping_cart,
                color: Colors.white,
                size: 25,
              ),
            ],
          ),
        ),
        backgroundColor: Color(0xFFE1BCA7),
      ),



      body: FutureBuilder<Map<String, dynamic>>(
        future: cartData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!['cartItems'].isEmpty) {
    return Center(
    child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    Image.asset(
    'assets/images/EmptyCartPng.png', // Replace with your actual image path
    width: 290,
    height: 290,
    ),

    Text(
    'Your cart is empty',
    style: TextStyle(
    color: Color(0xFFC48A74),
    fontWeight: FontWeight.bold,
    fontSize: 20,
    ),
    ),
    ],
    ),
    );
    }

    else {
            final cartItems = snapshot.data!['cartItems'];
            final totalItems = snapshot.data!['totalItems'];
            final totalPrice = snapshot.data!['totalPrice'];

            return Stack(
              children: [
                // Scrollable cart items list with transparent container
                Positioned.fill(
                  child: Container(
                    color: Colors.transparent,
                    child: ListView.builder(
                      padding: EdgeInsets.only(bottom: 220), // Space for the bottom summary
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];
                        final productId = item['productid']?.toString() ?? 'Unknown ID';

                        final decodedImage = (item['imageBase64'] != null && item['imageBase64'].isNotEmpty)
                            ? decodeBase64Image(item['imageBase64'])
                            : null;

                        // Determine if the item is local
                        final isLocalItem = item.containsKey('isLocal') && item['isLocal'] == true;

                        // Choose the correct price
                        final unitPrice = isLocalItem
                            ? double.tryParse(item['totalprice'].toString()) ?? 0.0
                            : double.tryParse(item['priceAfterSelling'].toString()) ?? 0.0;

                        final quantity = int.tryParse(item['quantity'].toString()) ?? 1;
                        final totalItemPrice = unitPrice * quantity;

                        return buildCartItem(
                          productId,
                          item['productname'] ?? 'Unknown Product',
                          '\$${totalItemPrice.toStringAsFixed(2)}',
                          decodedImage,
                          item['color_name'] ?? 'N/A',
                          item['size_name'] ?? 'N/A',
                          quantity,
                          item['userId']?.toString() ?? 'Unknown User',
                        );

                      },

                    ),
                  ),
                ),

                // White summary box floating above with shadow
                Positioned(
                  bottom: -17,
                  left: 0,
                  right: 0,
                  child: Container(
                    margin: EdgeInsets.all(20),
                    padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF847769).withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.attach_money, color: Color(0xFFC0907D), size: 20),
                            SizedBox(width: 5),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Price',
                                    style: GoogleFonts.dancingScript(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC0907D),
                                    ),
                                  ),
                                  Text(
                                    '\$${double.tryParse(totalPrice)?.toStringAsFixed(2) ?? '0.00'}',
                                    style: GoogleFonts.dancingScript(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC0907D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(Icons.shopping_cart, color: Color(0xFFC0907D), size: 20),
                            SizedBox(width: 5),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Items',
                                    style: GoogleFonts.dancingScript(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC0907D),
                                    ),
                                  ),
                                  Text(
                                    '$totalItems',
                                    style: GoogleFonts.dancingScript(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC0907D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 17),

                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () async {
                              final proceed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.white,
                                  title: Text(
                                    'Please Recheck Your Location',
                                    style: TextStyle(color: Color(0xFFB67C5E), fontSize: 20),
                                  ),
                                  content: Text(
                                    'Make sure your current location is correct before proceeding with payment.\nIf it is correct then press OK.',
                                    style: TextStyle(color: Color(0xFF8B7164)),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: Text(
                                        'Cancel',
                                        style: TextStyle(color: Color(0xFFDC9893)),
                                      ),
                                    ),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: Color(0xFFD59C80),
                                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      onPressed: () => Navigator.of(context).pop(true),
                                      child: Text(
                                        'OK',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              );

                              if (proceed == true) {
                                _showPaymentDialog(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFC98D77),
                              padding: EdgeInsets.symmetric(horizontal: 30, vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: Text(
                              'ORDER',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ),

                      ],
                    ),
                  ),
                ),
              ],
            );


          }
        },
      ),

      bottomNavigationBar: Container(
        color: Colors.white, // Make the background of the bottom navigation bar white
        child: NavBarUser(
          userId: LoginScreen.id,
          selectedIndex: _selectedIndex,
          onItemTapped: _onItemTapped,
        ),
      ),
    );
  }


  Widget buildCartItem(
      String productId , // Added productId to identify item
      String title,
      String price,
      Uint8List? decodedImage,
      String color,
      String size,
      int quantity,
      String userId // Pass userId to update SharedPreferences if needed
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      child: Container(
        padding: EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF847769).withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            SizedBox(width: 5),
            GestureDetector(
              onTap: () => removeCartItem(context,productId),
              child: Icon(Icons.close, color: Color(0xFFC2795B)),
            ),
            SizedBox(width: 13),

            // Display Image with ClipRRect
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 90,
                height: 90,

                child: decodedImage != null
                    ? Image.memory(
                  decodedImage,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  'assets/images/Woman.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
            ),


            SizedBox(width: 17),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.length > 14 ? '${title.substring(0, 14)}...' : title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFB6978B),
                  ),
                ),

                Text(price,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC0907D))),
                SizedBox(height: 4),
                Text('Color: $color, Size: $size',
                    style: TextStyle(fontSize: 11.5, color: Color(0xFF847769))),
              ],
            ),
            Spacer(),
            Row(
              children: [
                GestureDetector(
                  onTap: () => updateQuantity(productId, -1),
                  child: Icon(Icons.remove_circle, color: Color(0xFFA98476)),
                ),
                SizedBox(width: 5),
                Text('$quantity', // This should come from state
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC3ABA4))),
                SizedBox(width: 5),
                GestureDetector(
                  onTap: () => updateQuantity(productId, 1),
                  child: Icon(Icons.add_circle, color: Color(0xFFC2846A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

}
