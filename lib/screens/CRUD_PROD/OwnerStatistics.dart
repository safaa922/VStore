import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:virtual_store/screens/CRUD_PROD/BestSellingCategoryDetails.dart';
import 'package:virtual_store/screens/CRUD_PROD/MonthlyTotalAmount.dart';

import 'OwnerStatisticsOrderCount.dart';
import 'ProductRatingsDetails.dart';
import 'ProductViewsDetails.dart';

import 'SoldProductsDetails.dart';

class OwnerStatisticsScreen extends StatefulWidget {
  final String ownerId;

  const OwnerStatisticsScreen({required this.ownerId});

  @override
  _OwnerStatisticsScreenState createState() => _OwnerStatisticsScreenState();
}

class _OwnerStatisticsScreenState extends State<OwnerStatisticsScreen> {
  bool isLoading = false;
  String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/BGS6.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
           AppBar(
              title: Text(
                'Owner Statistics',
                style: TextStyle(
                  color: Color(0xFFB0715F),
                  fontWeight: FontWeight.bold,
                  fontSize: 21,
                ),
              ),
              backgroundColor: Color(0xFFB0715F).withOpacity(0.1),
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.only(left: 20.0, right: 0),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_outlined, color: Color(0xFFB0715F)),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              toolbarHeight: 80,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(vertical: 30.0),
                child: Center(
                  child: Wrap(
                    spacing: 20,
                    runSpacing: 20,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildStatCard(
                        'Number of Orders',
                        Icons.shopping_cart_outlined,
                        Color(0xFFB0715F),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OwnerStatisticsDetails(
                                ownerId: widget.ownerId,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Products Views',
                        Icons.remove_red_eye_outlined,
                        Color(0xFFB47E68),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductViewsDetails(
                                ownerId: widget.ownerId,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Products Ratings',
                        Icons.star_outline,
                        Color(0xFFA1887F),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductsRatingsDetails(
                                ownerId: widget.ownerId,
                              ),
                            ),
                          );
                        },
                      ),
                      _buildStatCard(
                        'Monthly Revenue',
                        Icons.attach_money_outlined,
                        Color(0xFFBCAAA4),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MonthlyTotalAmountDetails(
                                ownerId: widget.ownerId,
                              ),
                            ),
                          );
                        },
                      ),

                      _buildStatCard(
                        'Best Selling Stock',
                        Icons.trending_up_outlined,
                        Color(0xFFEFDCD5),
                            () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BestSellingCategoryDetails(
                                ownerId: widget.ownerId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        height: 150,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFB0715F).withOpacity(0.15),
              blurRadius: 3,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 26,
                color: color,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFFB0715F),
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}