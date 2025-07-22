import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class ProductsRatingsDetails extends StatefulWidget {
  final String ownerId;

  const ProductsRatingsDetails({required this.ownerId});

  @override
  _ProductsRatingsDetailsState createState() => _ProductsRatingsDetailsState();
}

class _ProductsRatingsDetailsState extends State<ProductsRatingsDetails> {
  List<dynamic> ratingsData = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchRatingsData();
  }

  Future<void> _fetchRatingsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://vstore.runasp.net/api/OwnerStatistics/owner-products-with-ratings/${widget.ownerId}'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        setState(() {
          ratingsData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load ratings data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFFD29489).withOpacity(0.18),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_outlined,
              color: Color(0xFFB7866B), size: 26),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Ratings Dashboard',
          style: GoogleFonts.marmelad(
            color: Color(0xFFB6866E),
            fontSize: 21,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Color(0xFFB48B76).withOpacity(0.2),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
        child: CircularProgressIndicator(
          color: Color(0xFFB89E91),
        ),
      )
          : errorMessage != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Text(
            'Error: $errorMessage',
            style: TextStyle(
              color: Color(0xFFB89E91),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xFFFAF6F3),
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Color(0xFFC97359).withOpacity(0.1), // 🔴 Red shadow
                blurRadius: 5,
                spreadRadius: 0,
                offset: Offset(0, 5),
              ),
            ],

          ),
          child: ratingsData.isNotEmpty
              ? SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: NeumorphicStatsTable(data: ratingsData),
          )
              : Center(
            child: Text(
              'No ratings data available',
              style: TextStyle(
                color: Color(0xFFB89E91).withOpacity(0.7),
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NeumorphicStatsTable extends StatelessWidget {
  final List<dynamic> data;

  const NeumorphicStatsTable({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.all(15.0),
          decoration: BoxDecoration(
            color: Color(0xFFFAF6F3),
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF856455).withOpacity(0.1),
                blurRadius: 3,
                offset: Offset(2, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Icon(Icons.local_offer, color: Color(0xFFD38467), size: 18),
                    SizedBox(width: 10),
                    Text(
                      'Product',
                      style: TextStyle(
                        color: Color(0xFFBF9A88),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD182), size: 19),
                    SizedBox(width: 5),
                    Text(
                      'Rating',
                      style: TextStyle(
                        color: Color(0xFFB08B78),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bar_chart, color: Color(0xFFC98664), size: 18),
                    SizedBox(width: 5),
                    Text(
                      'Count',
                      style: TextStyle(
                        color: Color(0xFFB08B78),
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Data rows
        ...data.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          double avgRating = (item['averageRating'] as num).toDouble();
          Color ratingColor = _getRatingColor(avgRating);

          // Alternate row background color
          final rowColor = index.isEven
              ? Color(0xFFFFFDFC) // even rows
              : Color(0xFFFAF6F3); // odd rows (lighter)


          return AnimatedContainer(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(15.0),
            decoration: BoxDecoration(
              color: rowColor,
              border: Border(
                bottom: BorderSide(
                  color: Color(0xFFD8C3B8).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                // Product name
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFE7BCAB),

                        ),
                        child: Center(
                          child: Icon(
                            Icons.local_offer,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item['productName'],
                          style: TextStyle(
                            color: Color(0xFFB89E91),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Average rating
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: avgRating / 5.0,
                              backgroundColor: Color(0xFFD8C3B8).withOpacity(0.2),
                              valueColor: AlwaysStoppedAnimation<Color>(ratingColor),
                              strokeWidth: 4,
                            ),
                          ),
                          Text(
                            avgRating.toStringAsFixed(1),
                            style: TextStyle(
                              color: Color(0xFFB89E91),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Ratings count
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: ratingColor.withOpacity(0.2),
                              blurRadius: 5,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.people,
                              color: Color(0xFFCCB3AB),
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              '${item['totalRatings']}',
                              style: TextStyle(
                                color: Color(0xFFB89E91),
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) {
      return Color(0xFFC58F73); // Calm brown for high ratings
    } else if (rating >= 3.0) {
      return Color(0xFFD2A089); // Light brown for medium ratings
    } else {
      return Color(0xFFD7B2A4); // Very light brown for low ratings
    }
  }
}