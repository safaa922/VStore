import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/constants.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:virtual_store/screens/BuyerDashboard.dart';
import 'package:virtual_store/NavBar.dart';
import 'package:virtual_store/screens/Cart_Items.dart';
import 'package:virtual_store/screens/LocationUpdate.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/screens/NavBarUser.dart';
import 'package:virtual_store/screens/Notification.dart';
import 'package:virtual_store/screens/ShopProducts.dart';
import 'package:virtual_store/screens/UserProfile.dart';
import 'package:http/http.dart' as http;

import 'Notification.dart';

class Shops extends StatefulWidget {
  static const String id = 'Shops';
  final String userId;
  Shops({required this.userId});
  int _selectedIndex = 0;
  @override
  _ShopListScreenState createState() => _ShopListScreenState();
}



class _ShopListScreenState extends State<Shops> {
  List<Map<String, dynamic>> shops = [];
  List<Map<String, dynamic>> filteredShops = [];
  List<String> favoriteShops = [];
  bool isLoading = true;
  String? errorMessage;
  String searchQuery = "";
  int _selectedIndex = 0;


  @override
  void initState() {
    super.initState();
    fetchShops();
    fetchFavorites();
    getUserId();
  }


  Future<bool> isTokenExpired(String token) async {
    try {
      // Decode JWT token
      Map<String, dynamic> payload = parseJwt(token);
      int? exp = payload["exp"]; // Expiry timestamp

      if (exp == null) return true; // Treat missing expiry as expired

      int currentTimestamp = DateTime
          .now()
          .millisecondsSinceEpoch ~/ 1000;
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

    final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])));
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('cart_items');
  }


// Function to retrieve stored auth token from session
  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the stored session token
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

      List<String> cart = prefs.getStringList('cart_$cartId') ??
          []; // Use cartId here

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


  void filterShops(String query) {
    setState(() {
      searchQuery = query.toLowerCase();
      filteredShops = shops
          .where((shop) =>
          shop['name'].toString().toLowerCase().contains(searchQuery))
          .toList();
    });
  }

  void _removeFromFavorites(String ownerId) async {
    if (ownerId.isEmpty) {
      print("Owner ID (shop ID) is empty. Cannot proceed.");
      return;
    }

    String? userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      print("User ID not found in preferences. Cannot proceed.");
      return;
    }

    const String apiUrl = 'http://vstore.runasp.net/api/FavList/DeleteFavList/';
    final String fullUrl = '$apiUrl$userId/$ownerId';

    try {
      print("Making DELETE API request to: $fullUrl");
      final response = await Dio().delete(fullUrl);

      if (response.statusCode == 200) {
        print("Shop removed from favorites successfully.");
        setState(() {
          fetchShops();
          fetchFavorites();
        });
      } else {
        print("Failed to remove shop from favorites. Status code: ${response
            .statusCode}");
      }
    } catch (e) {
      print("Error removing from favorites: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
            "Failed to remove from favorites. Please try again.")),
      );
    }
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<void> fetchFavorites() async {
    print("Fetching favorites initiated...");

    String? userId = await getUserId();
    if (userId == null) {
      print("User ID not found. Aborting fetchFavorites.");
      return;
    }

    print("User ID retrieved: $userId");

    const String apiUrl = 'http://vstore.runasp.net/api/User/GetFavListForUsers/';
    final String fullUrl = '$apiUrl$userId';

    print("API URL constructed: $fullUrl");

    try {
      print("Attempting API call...");
      final response = await Dio().get(fullUrl);
      print("API response received. Status code: ${response.statusCode}");

      if (!mounted) return; // Ensure widget is still mounted

      if (response.statusCode == 200) {
        print("Response data: ${response.data}");
        final List<dynamic> data = response.data;

        setState(() {
          favoriteShops = data.map((fav) => fav['ownerId'] as String).toList();
        });

        print("Favorite shops updated in state: $favoriteShops");
      } else {
        print("Failed to fetch favorites. Status code: ${response
            .statusCode}, Response: ${response.data}");
      }
    } catch (e) {
      print("Error during API call: $e");
    }

    print("fetchFavorites process completed.");
  }


  void _addToFavorites(String ownerId) async {
    if (ownerId.isEmpty) {
      print("Owner ID (shop ID) is empty. Cannot proceed.");
      return;
    }

    String? userId = await getUserId();
    if (userId == null || userId.isEmpty) {
      print("User ID not found in preferences. Cannot proceed.");
      return;
    }

    const String apiUrl = 'http://vstore.runasp.net/api/FavList/AddToFavList/';
    final String fullUrl = '$apiUrl$ownerId/$userId';

    try {
      print("Making API request to: $fullUrl");
      final response = await Dio().post(fullUrl);

      if (response.statusCode == 200) {
        print("Shop added to favorites successfully.");

        if (!mounted) return; // Ensure widget is still mounted

        setState(() {
          fetchShops();
          fetchFavorites();
        });
      } else {
        print("Failed to add shop to favorites. Status code: ${response
            .statusCode}");
      }
    } catch (e) {
      print("Error adding to favorites: $e");
      if (!mounted) return; // Ensure widget is still mounted

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Failed to add to favorites. Please try again.")),
      );
    }
  }

  @override
  void dispose() {
    print("ShopListScreen disposed. Cancelling API calls...");
    super.dispose();
  }


  Future<void> fetchShops() async {
    try {
      const String apiUrl = 'http://vstore.runasp.net/api/User/AllShops';
      print("Fetching shops from API: $apiUrl");

      final response = await Dio().get(apiUrl);
      print("Response: ${response.data}");

      final List<dynamic> data = response.data;

      if (!mounted) return; // Ensure widget is still mounted

      setState(() {
        shops = data
            .where((shop) =>
        shop['shop_Id'] !=
            "04f5c37a-40d9-421f-b1e7-5163469268a9") // Exclude the specific shop
            .map((shop) =>
        {
          'name': shop['shop_Name'] ?? 'Unnamed Shop',
          'image': shop['imageBase64'] ?? '',
          'shop_Id': shop['shop_Id'] ?? '',
        })
            .toList();

        filteredShops = List.from(shops);
        print("Shops: $shops");
        isLoading = false;
      });
    } catch (e) {
      print("Error: $e");
      if (!mounted) return; // Ensure widget is still mounted
      setState(() {
        errorMessage = 'Failed to load shops. Please try again.';
        isLoading = false;
      });
    }
  }


  void _onShopTap(String shop_Id, String shopName, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ShopProducts(
              userId: userId,
              ShopId: shop_Id,
              ShopName: shopName,

            ),
      ),
    );
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

  Widget _buildNavBarIcon(IconData icon, bool isSelected,
      {double size = 24.0}) {
    return Icon(
      icon,
      size: size,
      color: isSelected ? Colors.white : Colors.grey,
    );
  }

  Future<void> _onItemTapped(int index) async {
    print('Tapped index: $index');

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      print("Navigating to BuyerDashboard");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Shops(userId: widget.userId,)),
      );
    }

    else if (index == 1) {
      print("Navigating to Cart");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => Cart_Items()),
      );
    }
    else if (index == 3) {
      String? userId = await getUserId();
      print("Navigating to Profile");
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserProfile(userId: userId)),
        );
      }
    }
    else if (index == 2) {
      String? userId = await getUserId();
      print("Navigating to Notificationsuser");
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => Notificationsuser(userId: userId)),
        );
      }

      else {
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
        automaticallyImplyLeading: false,
        toolbarHeight: 94,
        title: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Row(
            children: [
              Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    padding: EdgeInsets.only(top: 0, right: 17, left: 17),
                    icon: Icon(Icons.menu, color: Color(0xFFFFFFFF), size: 28),
                    onPressed: () {
                      Scaffold.of(context).openDrawer(); // ✅ now it works
                    },
                  );
                },
              ),


              const Text(
                'Shops',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: const Color(0xFFDAB8A9),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(55),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: TextField(
              onChanged: filterShops,
              decoration: InputDecoration(
                hintText: 'Search by Shop name',
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

      // ✅ Add the drawer here
      drawer: Container(
        width: MediaQuery
            .of(context)
            .size
            .width * 0.53,
        color: Color(0xFFE4D1C2),
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
                logout(context); // Make sure logout accepts context
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.location_pin, size: 30, color: Colors.white),
              title: Text(
                'GPS',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LocationUpdateScreen(userId: widget.userId),
                  ),
                );
              },
            ),
          ],
        ),
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
          : filteredShops.isEmpty
          ? const Center(child: Text('No shops found.'))
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 16,
          childAspectRatio: 5 / 6,
        ),
        itemCount: filteredShops.length,
        itemBuilder: (context, index) {
          final shop = filteredShops[index];
          final isFavorite = favoriteShops.contains(shop['shop_Id']);
          final decodedImage = decodeBase64Image(shop['image']);

          return GestureDetector(
            onTap: () =>
                _onShopTap(shop['shop_Id'], shop['name'], widget.userId),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: decodedImage != null
                        ? Image.memory(
                      decodedImage,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    )
                        : Image.asset(
                      'assets/images/Woman.png',
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: isFavorite
                            ? Color(0xFFE07066)
                            : Colors.white,
                      ),
                      onPressed: () {
                        if (isFavorite) {
                          _removeFromFavorites(shop['shop_Id']);
                        } else {
                          _addToFavorites(shop['shop_Id']);
                        }
                      },
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Text(
                        shop['name'],
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
          );
        },
      ),

      bottomNavigationBar: NavBarUser(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
        userId: widget.userId,
      ),
    );
  }
}
