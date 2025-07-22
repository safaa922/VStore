import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/widgets.dart';

import 'package:url_launcher/url_launcher.dart';

import '../main.dart';

class OrdersScreen extends StatefulWidget {
  final String userId;
  const OrdersScreen({super.key, required this.userId});

  @override
  _OrdersScreenState createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with RouteAware {

  List<dynamic> orders = [];
  bool isLoading = true;
  Map<int, String> paymentStatusMap = {}; // orderId -> "success"/"pending"

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }
  @override
  void didPopNext() {
    // Called when coming back to this screen
    print('🔄 Returned to OrdersScreen – refreshing orders...');
    fetchOrders();
  }


  Future<String> fetchDeliveryCost(String userId, String shopId) async {
    final url = Uri.parse(
      'http://vstore.runasp.net/api/Location/distance?fromUserId=$userId&toUserId=$shopId',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['estimatedCostInPounds'] ?? "0 pounds";
      } else {
        return "0 pounds";
      }
    } catch (e) {
      return "0 pounds";
    }
  }




  Future<void> checkPaymentStatus(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('http://vstore.runasp.net/api/Stripe/GetPaymentStatus/$orderId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['paymentStatus'];

        if (mounted) {
          setState(() {
            paymentStatusMap[orderId] = status.toLowerCase();
          });
        }
      } else {
        print('⚠️ Failed to fetch payment status');
      }
    } catch (e) {
      print('❌ Error checking payment status: $e');
    }
  }


  Future<void> redirectToCheckout(int orderId) async {
    print('🧾 Creating Stripe Checkout Session for Order $orderId...');
    try {
      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Stripe/checkout-session/$orderId'),
        headers: {"Content-Type": "application/json"},
      );

      final data = json.decode(response.body);
      print('🔗 Checkout session created: $data');

      final checkoutUrl = data['url'];
      if (checkoutUrl != null) {
        print('🌐 Redirecting to Checkout URL: $checkoutUrl');
        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch Stripe Checkout URL.';
        }
      } else {
        throw 'No Checkout URL returned from server.';
      }
    } catch (e) {
      print('❌ Error during redirectToCheckout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start checkout: $e')),
      );
    }
  }



  Future<Map<String, dynamic>> createPaymentIntent(int orderId, String paymentMethodId) async {
    print('🔄 Creating PaymentIntent for order: $orderId with paymentMethodId: $paymentMethodId');
    try {
      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Stripe/pay-now/$orderId'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({'paymentMethodId': paymentMethodId}),
      );

      print('📡 Response status: ${response.statusCode}');
      print('📦 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        print('✅ PaymentIntent created: $decoded');
        return decoded;
      } else {
        throw Exception('❌ Failed to create payment intent. Status code: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Exception in createPaymentIntent: $e');
      rethrow;
    }
  }

  Future<void> startPayment(String clientSecret) async {
    print('⚙️ Initializing payment sheet with clientSecret: $clientSecret');
    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.light,
          merchantDisplayName: 'VStore',
        ),
      );

      print('📲 Presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();

      print('✅ Payment succeeded');
    } catch (e) {
      if (e is StripeException) {
        print('❌ StripeException: ${e.error.localizedMessage}');
      } else {
        print('❌ Unknown exception during startPayment: $e');
      }
      throw Exception('Payment failed');
    }
  }

  Future<void> payForOrder(int orderId) async {
    print('🧾 Initiating Stripe Checkout for Order $orderId...');
    try {
      // ✅ Call backend to get the Checkout Session URL
      final response = await http.post(
        Uri.parse('http://vstore.runasp.net/api/Stripe/checkout-session/$orderId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final checkoutUrl = data['url'];

        print('✅ Received Checkout URL: $checkoutUrl');

        // ✅ Open the Stripe Checkout page in browser
        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl), mode: LaunchMode.externalApplication);
        } else {
          throw Exception('🚫 Could not launch checkout URL.');
        }
      } else {
        throw Exception('❌ Failed to create checkout session. Status: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e) {
      print('❌ Error during payForOrder: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to start payment for Order $orderId')),
      );
    }
  }




  Future<void> fetchOrders() async {
    final url = Uri.parse('http://vstore.runasp.net/api/Order/get-orders/${widget.userId}');
    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        final fetchedOrders = json.decode(response.body);
        if (mounted) {
          setState(() {
            orders = fetchedOrders;
            isLoading = false;
          });
        }

        // Fetch payment statuses separately, safely
        for (var order in fetchedOrders) {
          checkPaymentStatus(order["order_Id"]);
        }

      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      print('Error fetching orders: $e');
    }
  }


  Future<void> deleteOrder(int orderId) async {
    final url = Uri.parse(
        'http://vstore.runasp.net/api/Order/delete-order/$orderId');
    try {
      final response =
      await http.delete(url, headers: {'Accept': 'application/json'});
      if (response.statusCode == 200) {
        setState(() {
          orders.removeWhere((order) => order["order_Id"] == orderId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted successfully')),
        );
      } else {
        throw Exception('Failed to delete order');
      }
    } catch (e) {
      print('Error deleting order: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete order')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Orders',
          style: GoogleFonts.aboreto(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: Color(0xFFEEB79F),
        elevation: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        toolbarHeight: 80,
      ),
      body: Column(
        children: [
          const SizedBox(height: 17), // Space under AppBar
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : orders.isEmpty
                ? const Center(child: Text('No orders found'))
                : ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                final userId = order["user_Id"];
                final shopId = order["order_Products"].first["shopId"];
                final orderId = order["order_Id"];
                final status = paymentStatusMap[orderId] ?? 'pending';

                return FutureBuilder<String>(
                  future: fetchDeliveryCost(userId, shopId),
                  builder: (context, snapshot) {
                    final deliveryRaw = snapshot.data ?? "0 pounds";
                    final deliveryCost = RegExp(r'\d+').stringMatch(deliveryRaw) ?? '0';

                    final deliveryCostValue = int.tryParse(RegExp(r'\d+').stringMatch(deliveryCost) ?? '0') ?? 0;
                    final totalWithDelivery = order["totalPrice"] + deliveryCostValue;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                      child: Row(
                        children: [
                          // Left: Order ID Badge
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8B397),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Right: Order Details
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF2F1E58).withOpacity(0.1),
                                    spreadRadius: 0.4,
                                    blurRadius: 3,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Row with Total Price and Delete Button
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(Icons.monetization_on, color: Color(0xFFD7AD95), size: 19),
                                            const SizedBox(width: 6),
                                            RichText(
                                              text: TextSpan(
                                                style: GoogleFonts.alata(
                                                  color: Color(0xFFD5AA92),
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                children: [
                                                  TextSpan(
                                                    text: 'Total: $totalWithDelivery \$ ',
                                                  ),
                                                  TextSpan(
                                                    text: '(Delivery: $deliveryCost)',
                                                    style: TextStyle(
                                                      fontSize: 11.5, // smaller than total
                                                      fontWeight: FontWeight.normal,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                          ],
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Color(0xFFDE867F), size: 22),
                                          onPressed: () {
                                            deleteOrder(order["order_Id"]);
                                          },
                                        ),
                                      ],
                                    ),

                                    // Thin Line
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        height: 1,
                                        width: 246,
                                        color: Color(0xFFD9AE96).withOpacity(0.5),
                                      ),
                                    ),

                                    const SizedBox(height: 18),

                                    // Products List
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        for (var product in order["order_Products"])
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 18.0, left: 5),
                                            child: Row(
                                              children: [
                                                if (product["photo"] != null)
                                                  Container(
                                                    width: 47,
                                                    height: 47,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius: BorderRadius.circular(8),
                                                      child: Image.memory(
                                                        base64Decode(product["photo"]),
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context, error, stackTrace) {
                                                          return Icon(Icons.broken_image, size: 50, color: Colors.grey);
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Text(
                                                    '${product["productName"]} , ${product["priceAfterSell"]} \$',
                                                    style: const TextStyle(
                                                      color: Color(0xFFD7A28C),
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.only(right: 10),
                                                  child: Container(
                                                    width: 80,
                                                    alignment: Alignment.centerRight,
                                                    child: Text(
                                                      'quantity: ${product["quntity"]}',
                                                      style: const TextStyle(
                                                        color: Color(0xFFD7A28C),
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                        // Pay Button
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Padding(
                                            padding: const EdgeInsets.only(right: 11, bottom: 3),
                                            child: order["paymentMethod"] == "Cash"
                                                ? Text(
                                              'Cash',
                                              style: TextStyle(
                                                color: Color(0xFFD78264),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            )
                                                : ElevatedButton.icon(
                                              onPressed: status == 'success'
                                                  ? null
                                                  : () async {
                                                final confirmed = await showDialog<bool>(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    backgroundColor: Colors.white,
                                                    title: Text(
                                                      'Confirm Payment',
                                                      style: TextStyle(color: Color(0xFFB67C5E), fontSize: 20),
                                                    ),
                                                    content: Text(
                                                      'Are you sure you want to pay for Order $orderId?',
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
                                                          'Pay',
                                                          style: TextStyle(color: Colors.white),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );

                                                if (confirmed == true) {
                                                  setState(() {
                                                    isLoading = true;
                                                  });

                                                  await payForOrder(orderId);
                                                  await Future.delayed(Duration(seconds: 2));

                                                  if (mounted) {
                                                    await fetchOrders();
                                                  }
                                                }
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Color(0xFFE8B899),
                                                disabledBackgroundColor: Color(0xFFA1DC8D),
                                                disabledForegroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                                textStyle: const TextStyle(fontSize: 13),
                                              ),
                                              icon: Icon(
                                                status == 'success' ? Icons.check_circle : Icons.payment,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                              label: Text(
                                                status == 'success' ? 'Success' : 'Pay Now',
                                                style: const TextStyle(color: Colors.white, fontSize: 12.7),
                                              ),
                                            ),
                                          ),
                                        )

                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            )

          ),
        ],
      ),
    );
  }
}
