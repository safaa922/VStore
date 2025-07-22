import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductViewsDetails extends StatefulWidget {
  final String ownerId;

  const ProductViewsDetails({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  _ProductViewsDetailsState createState() => _ProductViewsDetailsState();
}

class _ProductViewsDetailsState extends State<ProductViewsDetails> {
  List<dynamic> productViewsData = [];
  bool isLoading = true;
  String? errorMessage;
  int touchedIndex = -1;

  // Updated Color scheme with softer brown tones
  final primaryColor = const Color(0xFFA67C52); // Softer brown
  final secondaryColor = const Color(0xFFC4A484); // Lighter brown
  final accentColor = const Color(0xFFE5D5C5); // Very light brown
  final backgroundColor = const Color(0xFFF8F1E9);
  final textColor = const Color(0xFF6D4C41); // Softer dark brown

  @override
  void initState() {
    super.initState();
    _fetchProductViewsData();
  }

  Future<void> _fetchProductViewsData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://vstore.runasp.net/api/OwnerStatistics/products-views/${widget.ownerId}'),
        headers: {'accept': '*/*'},
      );

      if (response.statusCode == 200) {
        setState(() {
          productViewsData = json.decode(response.body);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load product views data: ${response.statusCode}');
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
    double totalViews = productViewsData.isNotEmpty
        ? productViewsData
        .map((item) => (item['viewCount'] as num).toDouble())
        .reduce((a, b) => a + b)
        : 0.0;

    var topViewed = productViewsData.isNotEmpty && totalViews > 0
        ? productViewsData.reduce((a, b) =>
    (a['viewCount'] as num) > (b['viewCount'] as num) ? a : b)
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/BGS6.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Blur effect
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // adjust blur intensity
            child: Container(
              color: Color(0xFFC5AAA0).withOpacity(0.02), // optional tint over blur
            ),
          ),


          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_outlined,
                            color: Color(0xFFC47F69), size: 26),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Products Views',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC47F69),
                            letterSpacing: 1.1,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.refresh,
                            color: Color(0xFFC47F69), size: 26),
                        onPressed: _fetchProductViewsData,
                      ),
                    ],
                  ),
                ),

                // Main content
                Expanded(
                  child: isLoading
                      ? Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFB0715F),
                    ),
                  )
                      : errorMessage != null
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error: $errorMessage',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color(0xFFB4715D),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                      : productViewsData.isEmpty
                      ? Center(
                    child: Text(
                      'No product views data available',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFFB4715D),
                      ),
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        if (topViewed != null) ...[
                          _buildTopProductCard(topViewed, totalViews),
                          const SizedBox(height: 20),
                        ],
                        _buildPieChartSection(totalViews),
                        const SizedBox(height: 20),
                        _buildTotalViewsCard(totalViews),
                        const SizedBox(height: 20),
                        _buildProductsList(totalViews),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTopProductCard(Map<String, dynamic> topViewed, double totalViews) {
    double percentage = (topViewed['viewCount'] as num) / totalViews * 100;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB4715D).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC26D59).withOpacity(0.94), Color(0xFFDFA581).withOpacity(0.9)],
              ),
            ),
            child: Icon(
              Icons.star,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Most Viewed Product',
                  style: TextStyle(
                    fontSize: 15,
                    color: textColor.withOpacity(0.7),
                  ),
                ),
                Text(
                  topViewed['productName'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC47F69),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${topViewed['viewCount']} views (${percentage.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 14,
                    color: textColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartSection(double totalViews) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB96C57).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Views Distribution',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD58A71),
            ),
          ),

          SizedBox(
            height: 250,
            child: totalViews > 0
                ? PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        touchedIndex = -1;
                        return;
                      }
                      touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                sectionsSpace: 2,
                centerSpaceRadius: 60,
                sections: productViewsData.map((product) {
                  final index = productViewsData.indexOf(product);
                  final viewCount = (product['viewCount'] as num).toDouble();
                  final percentage = totalViews > 0 ? (viewCount / totalViews) * 100 : 0;
                  final isTouched = index == touchedIndex;

                  return PieChartSectionData(
                    value: viewCount,
                    color: _getColor(index),
                    radius: isTouched ? 30 : 25,
                    title: isTouched ? '${percentage.toStringAsFixed(1)}%' : '',
                    titleStyle: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Color(0xFFB96C57).withOpacity(0.3),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    badgeWidget: isTouched
                        ? Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        product['productName'] ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: _getColor(index),
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    )
                        : null,
                    badgePositionPercentageOffset: 0.98,
                  );
                }).toList(),
              ),
            )
                : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.visibility_off,
                    size: 50,
                    color: Color(0xFFB4715D).withOpacity(0.5),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'No views yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB4715D).withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalViewsCard(double totalViews) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC26D59).withOpacity(0.9), Color(0xFFDFA581).withOpacity(0.9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB96C57).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Views',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            totalViews.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(double totalViews) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB96C57).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Products Details',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFFBE7257),
            ),
          ),
          const SizedBox(height: 10),
          ...productViewsData.map((product) {
            final index = productViewsData.indexOf(product);
            final viewCount = product['viewCount'] as num;
            final percentage = totalViews > 0 ? (viewCount / totalViews) * 100 : 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColor(index),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      product['productName'] ?? 'Unknown Product',
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC79579),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Color _getColor(int index) {
    const colors = [
      Color(0xFFCB7E63), // Softer brown
      Color(0xFFCC967A), // Light brown
      Color(0xFFE5D5C5), // Very light brown
      Color(0xFFB27863), // Medium brown
      Color(0xFFD4B59E), // Light medium brown
      Color(0xFFB0624A), // Darker brown
      Color(0xFF794539), // Soft dark brown
    ];
    return colors[index % colors.length];
  }
}