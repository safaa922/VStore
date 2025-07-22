import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:virtual_store/NavBar.dart';
import 'package:virtual_store/screens/EditOwnerProfile.dart';
import 'package:virtual_store/screens/Login.dart';
import 'package:virtual_store/screens/Notification.dart';

import 'package:virtual_store/screens/OwnerDashBoard.dart';
import 'package:virtual_store/screens/Shops.dart';


class OwnerProfile extends StatefulWidget {
  final String ownerId;

  OwnerProfile({required this.ownerId});

  @override
  _OwnerProfileState createState() => _OwnerProfileState();
}

class _OwnerProfileState extends State<OwnerProfile> {
  late Future<OwnerProfileModel> futureOwnerProfile;
  int _selectedIndex = 3;


  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // Retrieve the 'id' from SharedPreferences
  }

  Future<void> _onItemTapped(int index) async {
    print('Tapped index: $index'); // Debugging: check if the correct index is tapped.

    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      // الانتقال للـ OwnerDashboard
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => OwnerDashboard(userId: widget.ownerId)),
      );
    } else if (index == 2) {
      String? userId = await getUserId();
      if (userId != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => Notificationsuser(userId:userId)),
        );
      } else if (index == 3) {
        String? ownerId = await getUserId();
        if (ownerId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OwnerProfile(ownerId: ownerId)),
          );
        }
        else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("No owner ID found. Please log in.")),
          );
        }
      }
    }
  }


  void _loadData() {
    futureOwnerProfile = fetchOwnerProfile(widget.ownerId);
  }

  Future<OwnerProfileModel> fetchOwnerProfile(String ownerId) async {
    final response = await http.get(Uri.parse('http://vstore.runasp.net/api/Owner/OwnerProfile/$ownerId'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      return OwnerProfileModel.fromJson(data);
    } else {
      throw Exception('Failed to load owner profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ));

    return Scaffold(
      backgroundColor: Colors.white, // Ensure background color does not interfere
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
              child: FutureBuilder<OwnerProfileModel>(
                future: futureOwnerProfile,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData) {
                    return Center(child: Text('No data found'));
                  }

                  final ownerProfile = snapshot.data!;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      return Column(
                        children: [
                          _buildProfileSection(ownerProfile),
                          const SizedBox(height: 39),
                          const Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [],
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Navigation bar placed on top
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              selectedIndex: _selectedIndex,
              onItemTapped: _onItemTapped, userId: widget.ownerId,
            ),
          ),
        ],
      ),
    );
  }




  Widget _buildProfileSection(OwnerProfileModel ownerProfile) {
    return Column(
      children: [
        const SizedBox(height: 36),
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
                backgroundImage: ownerProfile.imageBase64 != null && ownerProfile.imageBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(ownerProfile.imageBase64!))
                    : AssetImage('assets/images/default_profile.png') as ImageProvider,
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
                      builder: (context) => EditOwnerProfile(
                        ownerProfile: OwnerProfileModel(
                          id: ownerProfile.id,
                          fName: ownerProfile.fName,
                          lName: ownerProfile.lName,
                          email: ownerProfile.email,
                          userName: ownerProfile.userName,
                          address: ownerProfile.address,
                          phoneNumber: ownerProfile.phoneNumber,
                          shopName: ownerProfile.shopName,
                          shop_description: ownerProfile.shop_description,
                          imageBase64: ownerProfile.imageBase64,
                        ),
                      ),
                    ),
                  );

                  if (updatedProfile != null) {
                    setState(() {
                      futureOwnerProfile = Future.value(updatedProfile);
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
        const SizedBox(height: 16),
        Text(
          "${ownerProfile.fName ?? 'Unknown'} ${ownerProfile.lName ?? 'User'}",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFC27F6F),
          ),
        ),
        Text(
          ownerProfile.userName ?? 'No Username',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFFAB7D6F),
          ),
        ),
        const SizedBox(height: 55),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 31.0),
          child: Column(
            children: [
              // Row for location, phone, and shop name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard(Icons.location_on, ownerProfile.address ?? 'No Address', Color(0xFFE5B9A0)),
                  _buildInfoCard(Icons.phone, ownerProfile.phoneNumber ?? 'No Phone', Color(0xFFD6B4A2)),


                  _buildInfoCard(Icons.store, ownerProfile.shopName ?? 'No Shop Name', Color(
                      0xFFEAD8CC)),
                ],
              ),
              const SizedBox(height: 20),
              // Row for email with increased width
              Row(
                children: [
                  Container(
                    width: 330, // Adjust width here
                    child: _buildInfoCard(Icons.email, ownerProfile.email ?? 'No Email', Color(0xFFF4EBE7)),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              // Row for shop description with increased width
              Row(
                children: [
                  Container(
                    width: 330, // Adjust width here
                    height: 100, // Adjust height here
                    child: _buildInfoCard(
                      Icons.description,
                      ownerProfile.shop_description ?? 'No Shop Description',
                      Color(0xFFF4EBE7),
                      textAlign: TextAlign.start, // Align text to the top
                    ),
                  ),
                ],
              ),

            ],
          ),
        ),

      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String text, Color backgroundColor,{TextAlign textAlign = TextAlign.center}) {
    Color iconColor = Colors.white;
    Color textColor = Colors.white;

    if (icon == Icons.description || icon == Icons.email || icon == Icons.store) {
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
            size: 17,
          ),
          const SizedBox(width: 8),
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
}

class OwnerProfileModel {
  final String? id;
  final String? fName;
  final String? lName;
  final String? email;
  final String? userName;
  final String? address;
  final String? phoneNumber;
  final String? shopName;
  final String? shop_description;
  String? imageBase64;
  final DateTime? registirationDate;
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'No Date';
    }
    try {
      DateTime date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}'; // Format: DD/MM/YYYY
    } catch (e) {
      return 'Invalid Date';
    }
  }


  OwnerProfileModel({
    required this.id,
    this.fName,
    this.lName,
    this.email,
    this.userName,
    this.address,
    this.phoneNumber,
    this.shopName,
    this.shop_description,
    this.imageBase64,
    this.registirationDate,
  });

  factory OwnerProfileModel.fromJson(Map<String, dynamic> json) {
    return OwnerProfileModel(
      id: json['id'] as String?,
      fName: json['fName'] as String? ?? 'Unknown',
      lName: json['lName'] as String? ?? 'User',
      email: json['email'] as String? ?? 'No Email',
      userName: json['userName'] as String? ?? 'No Username',
      address: json['address'] as String? ?? 'No Address',
      phoneNumber: json['phoneNumber'] as String? ?? 'No Phone',
      shopName: json['shop_Name'] as String? ?? 'No Shop Name',
      shop_description: json['shop_description'] as String? ?? 'No Shop Description',
      imageBase64: json['imageBase64'] as String? ?? '',
      //registirationDate: json['registirationDate'] as DateTime? ?? 'none',
    );
  }
}
