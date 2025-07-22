import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_links/app_links.dart';
import 'package:virtual_store/screens/shops.dart';
import 'package:virtual_store/screens/OwnerDashBoard.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/TokenManager.dart';
import 'package:virtual_store/screens/successfulPayment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = 'pk_test_51Qw6e9FPcMZyJkf03PrQf5puApE2k5XqCxqmHi8Q4N6QCPpYTRCjjqZBz04zecFG1VnwWTG0gK3NLQCDKCB3e3WE00sck6HiPU';

  Stripe.urlScheme = 'vstore';
  await Stripe.instance.applySettings();  // ✅ now allowed
  runApp(MyApp());
}



final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
StreamSubscription? _sub;

final appLinks =  AppLinks();

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorObservers: [routeObserver],
      title: 'Flutter Demo',
      navigatorKey: navigatorKey, // Set the global navigator key
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(), // Start from splash screen
    );
  }
}

// SplashScreen initializes the app and checks user authentication
class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _handleIncomingLinks();

    // Start token expiration checking
    TokenManager().startChecking();

    // Simulating a delay before checking authentication
    Future.delayed(Duration(seconds: 2), () async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token != null && token.isNotEmpty) {
        String? role = prefs.getString('user_role');
        String? userId = prefs.getString('id');

        if (role == 'buyer') {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => Shops(userId: userId ??'')),
          );
        } else {
          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute(builder: (context) => OwnerDashboard(userId: userId ?? '')),
          );
        }
      } else {
        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute(builder: (context) => LoginScreen()),
        );
      }
    });
  }

  void _handleIncomingLinks() async {
    try {
      // Handle initial app link (cold start)
      final initialUri = await appLinks.getInitialAppLink();
      if (initialUri != null && initialUri.scheme == 'vstore' && initialUri.host == 'checkout-success') {
        final sessionId = initialUri.queryParameters['session_id'];
        // Navigate to the successful payment screen with the sessionId
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => successfulPayment(sessionId: sessionId),
          ),
        );
      }

      // Listen for incoming links while app is running
      _sub = appLinks.uriLinkStream.listen((uri) {
        if (uri != null && uri.scheme == 'vstore' && uri.host == 'checkout-success') {
          final sessionId = uri.queryParameters['session_id'];
          // Navigate to the successful payment screen with the sessionId
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => successfulPayment(sessionId: sessionId),
            ),
          );
        }
      }, onError: (err) {
        print('❌ Deep link error: $err');
      });
    } catch (e) {
      print('❌ Error getting initial link: $e');
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
