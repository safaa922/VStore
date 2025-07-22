import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/main.dart';
import 'package:http/http.dart' as http;

class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  Timer? _tokenCheckTimer;
  bool _isLoggingOut = false; // Prevent infinite loop

  void startChecking() {
    checkTokenExpiration(); // Check immediately

    _tokenCheckTimer?.cancel(); // Prevent multiple timers
    _tokenCheckTimer = Timer.periodic(Duration(seconds: 12), (timer) {
      checkTokenExpiration();
    });
  }

  Future<void> checkTokenExpiration() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? expireOn = prefs.getString('token_expiry');

    if (expireOn != null) {
      DateTime expiryTime = DateTime.parse(expireOn);
      if (DateTime.now().isAfter(expiryTime)) {
        print("Token expired. Logging out...");
        await logoutUser(navigatorKey.currentContext!);
      } else {
        print("Token is still valid.");
      }
    }
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id');
  }

  Future<String?> getAuthToken() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<bool> isTokenExpired(String token) async {
    try {
      Map<String, dynamic> payload = parseJwt(token);
      int? exp = payload["exp"];

      if (exp == null) return true;

      int currentTimestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      return currentTimestamp > exp;
    } catch (e) {
      print("Error decoding token: $e");
      return true;
    }
  }

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

      if (authToken == null || userId == null) {
        print("Error: Missing authentication token or user ID.");
        return;
      }

      if (await isTokenExpired(authToken)) {
        print("Token expired. Logging out...");
        await logoutUser(context);
        return;
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> cart = prefs.getStringList('cart_$userId') ?? [];

      if (cart.isEmpty) {
        print("No items to save.");
        return;
      }

      for (String item in cart) {
        Map<String, dynamic> cartItem = jsonDecode(item);

        final url = Uri.parse(
          'http://vstore.runasp.net/api/Cart/add-product-to-cart/$userId?Product_id=${cartItem['productId']}&quantity=${cartItem['quantity']}',
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
          print("Failed to save cart item: ${cartItem['productId']}");
        }
      }

      await prefs.remove('cart_$userId');
      print("Cart successfully saved and cleared.");
    } catch (e) {
      print('Error saving cart to database: $e');
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    if (_isLoggingOut) {
      print("Logout already in progress. Skipping...");
      return;
    }

    _isLoggingOut = true; // Set flag to prevent multiple calls
    print("Logging out user...");

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = await getUserId();
    String? authToken = await getAuthToken();

    if (userId != null && authToken != null) {
      await saveCartToDatabase(context);
    } else {
      print("User ID or auth token missing, skipping cart save.");
    }

    await prefs.remove('token');
    await prefs.remove('token_expiry');
    await prefs.remove('user_role');
    await prefs.remove('id');

    print("Cleared authentication data, cart saved.");

    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
      );
    } else {
      print("Navigator key is null, cannot navigate.");
    }

    _isLoggingOut = false; // Reset flag after logout
  }
}
