
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:virtual_store/screens/Cart_Items.dart';
import 'package:virtual_store/screens/EditUserProfile.dart';
import 'package:virtual_store/screens/Notification.dart';
import 'package:virtual_store/screens/Orders.dart';
import 'package:virtual_store/screens/ShopProducts.dart';

import 'NavBarUser.dart';
import 'Shops.dart';

class UserProfile extends StatefulWidget {
  final String userId;
  int _selectedIndex = 3;


  UserProfile({required this.userId});

  @override
  _UserProfileState createState() => _UserProfileState();
}

class _UserProfileState extends State<UserProfile> {
  int _selectedIndex = 3;
  late Future<UserProfileModel> futureUserProfile;
  late Future<List<ShopModel>> futureFavoriteShops;
  bool showFavoriteShops = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    futureUserProfile = fetchUserProfile(widget.userId);
    futureFavoriteShops = fetchFavoriteShops(widget.userId);
  }

  Future<UserProfileModel> fetchUserProfile(String userId) async {
    final response = await http.get(
        Uri.parse('http://vstore.runasp.net/api/User/GetUserProfile/$userId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return UserProfileModel.fromJson(data);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  Future<List<ShopModel>> fetchFavoriteShops(String userId) async {
    try {
      final url = 'http://vstore.runasp.net/api/User/GetFavListForUsers/$userId';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        print('Fetched Shops Count: ${data.length}');
        List<ShopModel> shops = data.map((shop) {
          print('Processing shop: ${shop['shop_Name']}');
          return ShopModel.fromJson(shop);
        }).toList();

        return shops;
      } else {
        print('Error fetching shops: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception: $e');
      return [];
    }
  }


  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/ProfileBg6.png'),
                fit: BoxFit.fill,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  FutureBuilder<UserProfileModel>(
                    future: futureUserProfile,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (!snapshot.hasData) {
                        return Center(child: Text('No data found'));
                      }

                      final userProfile = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileSection(userProfile),
                          const SizedBox(height: 32),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => OrdersScreen(userId: widget.userId)), // Replace with your Orders screen widget
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Orders",
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFC58475),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.add_shopping_cart_outlined,
                                    color: Color(0xFFC58475),
                                    size:21
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 17),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              // Makes the row wrap its children
                              children: [
                                Text(
                                  "Favorite Shops",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC58475),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Spacing between text and icon
                                Icon(
                                  Icons.favorite,
                                  color: Color(0xFFCB816F),
                                  size:21
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),
                          // Space below the section title
                        ],
                      );
                    },
                  ),
                  Expanded(
                    child: FutureBuilder<List<ShopModel>>(
                      future: futureFavoriteShops,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return Container(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Image.asset(
                                    'assets/images/shopPng2.png',
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.fill,
                                  ),

                                  Text(
                                    'Your Fav shops will appear here',
                                    style: TextStyle(
                                      color: Color(0xFFC98D7F),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );

                        }


                        final favoriteShops = snapshot.data!;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 26),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 11,
                              mainAxisSpacing: 11,
                              childAspectRatio: 0.9,
                            ),
                            itemCount: favoriteShops.length,
                            itemBuilder: (context, index) {
                              final shop = favoriteShops[index];
                              return _buildShopCard(
                                  shop.shopName ?? "Unknown Shop",
                                  shop.imageBase64 ?? "", shop.ownerId,
                              widget.userId
                              );
                            },


                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: NavBarUser(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped,
              userId: widget.userId,
            ),
          ),
        ],
      ),
    );
  }


  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // Retrieve the 'id' from SharedPreferences
  }

  Future<void> _onItemTapped(int index) async {
    print(
        'Tapped index: $index'); // Debugging: check if the correct index is tapped.

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // Navigate to BuyerDashboard
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
    }

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


  Widget _buildProfileSection(UserProfileModel userProfile) {
    return Column(
      children: [
        const SizedBox(height: 30),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 144,
              height: 144,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Color(0xFFC28779),
                  width: 2.2,
                ),
              ),
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.transparent,
                backgroundImage: userProfile.imageBase64 != null &&
                    userProfile.imageBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(userProfile.imageBase64!))
                    : AssetImage(
                    'assets/images/default_profile.png') as ImageProvider,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () async {
                  final updatedProfile = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          EditUserProfile(
                            userProfile: UserProfileModel(
                              id: userProfile.id,
                              fName: userProfile.fName,
                              lName: userProfile.lName,
                              email: userProfile.email,
                              userName: userProfile.userName,
                              address: userProfile.address,
                              phoneNumber: userProfile.phoneNumber,
                              imageBase64: userProfile.imageBase64,
                            ),
                          ),
                    ),
                  );

                  if (updatedProfile != null) {
                    setState(() {
                      futureUserProfile = Future.value(updatedProfile);
                    });
                  }
                },
                child: Container(
                  width: 35,
                  height: 35,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFFE0AD92),
                  ),
                  child: Icon(
                    Icons.edit,
                    size: 20,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "${userProfile.fName ?? 'Unknown'} ${userProfile.lName ?? 'User'}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC27F6F),
          ),
        ),
        Text(
          userProfile.userName ?? 'No Username',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFAB7D6F),
          ),
        ),
        const SizedBox(height: 50),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 27.0),
          child: Column(
            children: [
              // Location and Phone on the same row with reduced font size
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                // Aligning at the start
                children: [
                  _buildInfoCard(
                      Icons.location_on, userProfile.address ?? 'No Address',
                      Color(0xFFE5B9A0)),
                  const SizedBox(width: 15), // Reduce the space here
                  _buildInfoCard(
                      Icons.phone, userProfile.phoneNumber ?? 'No Phone',
                      Color(0xFFD6B4A2)),
                ],
              ),

              const SizedBox(height: 14),
              // Email on a new row with reduced font size
              Container(
                width: 280, // Adjust width here
                child: _buildInfoCard(
                    Icons.email, userProfile.email ?? 'No Email',
                    Color(0xFFF4EBE7)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String text, Color backgroundColor,
      {TextAlign textAlign = TextAlign.center}) {
    Color iconColor = Colors.white;
    Color textColor = Colors.white;

    if (icon == Icons.description || icon == Icons.email) {
      iconColor = Color(0xFFA78074);
      textColor = Color(0xFFA78074);
    }

    return Container(
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(9.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            textAlign: textAlign,
            style: TextStyle(
              fontSize: 11.8,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFavoriteShopsSection() {
    return GestureDetector(
      onTap: () {
        setState(() {
          showFavoriteShops = !showFavoriteShops;
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns items properly
        children: [


          Row(
            children: [
              const SizedBox(width: 33),
              Text(
                "Favorite Shops",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFC08678),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.favorite,
                color: Color(0xFFC08678),
              ),
            ],
          ),
          const SizedBox(height: 20), // Adds space below the text
        ],
      ),
    );
  }


  Widget _buildShopCard(String shopName, String imageBase64, String ownerId,String userId) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ShopProducts(ShopId: ownerId,ShopName: shopName,userId: userId,)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageBase64.isNotEmpty
                  ? Image.memory(
                base64Decode(imageBase64),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              )
                  : Image.asset(
                'assets/images/default_shop.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 11,horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Text(
                shopName,
                textAlign: TextAlign.start,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
  class UserProfileModel {
  final String? id;
  final String? fName;
  final String? lName;
  final String? email;
  final String? userName;
  final String? address;
  final String? phoneNumber;
  String? imageBase64;

  UserProfileModel({
    required this.id,
    this.fName,
    this.lName,
    this.email,
    this.userName,
    this.address,
    this.phoneNumber,
    this.imageBase64,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String?,
      fName: json['fName'] as String? ?? 'Unknown',
      lName: json['lName'] as String? ?? 'User',
      email: json['email'] as String? ?? 'No Email',
      userName: json['userName'] as String? ?? 'No Username',
      address: json['address'] as String? ?? 'No Address',
      phoneNumber: json['phoneNumber'] as String? ?? 'No Phone',
      imageBase64: json['imageBase64'] as String? ?? '',
    );
  }
}

class ShopModel {
  final String ownerId;
  final String? shopName;
  final String? imageBase64;


  ShopModel({
    required this.ownerId,
    this.shopName,
    this.imageBase64,

  });

  factory ShopModel.fromJson(Map<String, dynamic> json) {
    return ShopModel(
      ownerId: json['ownerId'] as String,
      shopName: json['shop_Name'] as String? ?? 'No Name',
      imageBase64: json['imageBase64'] as String? ?? '',

    );
  }
}
