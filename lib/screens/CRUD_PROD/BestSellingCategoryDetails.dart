import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BestSellingCategoryDetails extends StatefulWidget {
  final String ownerId;

  const BestSellingCategoryDetails({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  _BestSellingCategoryDetailsState createState() => _BestSellingCategoryDetailsState();
}

class _BestSellingCategoryDetailsState extends State<BestSellingCategoryDetails> {
  int? selectedYear;
  int? selectedMonth;
  List<Map<String, dynamic>> categoryData = [];
  bool isLoading = false;
  String? errorMessage;

  List<int> years = [];
  final List<int> months = List.generate(12, (index) => index + 1);

  @override
  void initState() {
    super.initState();
    _initializeYears();
    // Set default to current year/month
    selectedYear = DateTime.now().year;
    selectedMonth = DateTime.now().month;
    _fetchCategoryData();
  }

  void _initializeYears() {
    final currentYear = DateTime.now().year;
    years = List.generate(5, (index) => currentYear - 2 + index);
  }

  Future<void> _fetchCategoryData() async {
    if (selectedYear == null || selectedMonth == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = 'http://vstore.runasp.net/api/OwnerStatistics/sold-main-categories/${widget.ownerId}/$selectedYear/$selectedMonth';
      final response = await http.get(Uri.parse(url), headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          categoryData = data.map((item) => {
            'category': item['category'] as String,
            'totalQuantitySold': item['totalQuantitySold'] as int,
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load category data: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Color(0xFFB0715F),
        ),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    final themeColor = Color(0xFFB0715F);
    final secondaryColor = Color(0xFFDFB7A1);

    double maxValue = categoryData.isNotEmpty
        ? categoryData
        .map((data) => (data['totalQuantitySold'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b)
        : 10.0;
    double chartMaxY = ((maxValue / 10).ceil() * 10) * 1.3;

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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // App Bar Replacement
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.arrow_back_ios_new_outlined,
                                color: themeColor, size: 26),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Best Selling Categories',
                              style: TextStyle(
                                color: themeColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(width: 58),
                        ],
                      ),
                    ),

                    // Date Selection Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      color: Colors.white,
                      shadowColor: themeColor.withOpacity(0.3),
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButtonFormField<int>(
                                  value: selectedYear,
                                  hint: Text('Year',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 13)),
                                  items: years.map((year) {
                                    return DropdownMenuItem(
                                      value: year,
                                      child: Text(
                                        year.toString(),
                                        style: TextStyle(
                                          color: themeColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedYear = value;
                                      _fetchCategoryData();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.calendar_today,
                                        color: themeColor),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  canvasColor: Colors.white,
                                ),
                                child: DropdownButtonFormField<int>(
                                  value: selectedMonth,
                                  hint: Text('Month',
                                      style: TextStyle(
                                          color: themeColor, fontSize: 13)),
                                  items: months.map((month) {
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                        month.toString(),
                                        style: TextStyle(
                                          color: themeColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedMonth = value;
                                      _fetchCategoryData();
                                    });
                                  },
                                  decoration: InputDecoration(
                                    prefixIcon: Icon(Icons.date_range,
                                        color: themeColor),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    if (selectedYear != null && selectedMonth != null)
                      Text(
                        'Overview for ${_getMonthName(selectedMonth!)} $selectedYear',
                        style: TextStyle(
                          fontSize: 17,
                          color: Color(0xFFC0977F),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),

                    SizedBox(height: 24),

                    // Chart or Status
                    SizedBox(
                      height: 350,
                      child: isLoading
                          ? Center(
                          child:
                          CircularProgressIndicator(color: Colors.white))
                          : categoryData.isEmpty
                          ? Center(
                        child: Text(
                          'No category data available',
                          style: TextStyle(
                              fontSize: 18, color: Colors.white),
                        ),
                      )
                          : Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        shadowColor: themeColor.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Text(
                                'Sales by Category',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Color(0xFFBD7F5B),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              Expanded(
                                child: LineChart(
                                  _buildChartData(chartMaxY,
                                      themeColor, secondaryColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    // Category Details
                    if (!isLoading && categoryData.isNotEmpty)
                      Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        color: Colors.white,
                        shadowColor: themeColor.withOpacity(0.3),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Category Details',
                                style: TextStyle(
                                  fontSize: 17,
                                  color: themeColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 16),
                              ...categoryData.map(
                                      (data) => _buildCategoryItem(data, themeColor)),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _buildChartData(double maxY, Color themeColor, Color secondaryColor) {
    return LineChartData(
        minY: 0,
        maxY: maxY,
        lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
        getTooltipColor: (_) => themeColor.withOpacity(0.8),
    getTooltipItems: (touchedSpots) {
    return touchedSpots.map((spot) {
    final category = categoryData[spot.x.toInt()]['category'];
    return LineTooltipItem(
    '$category\n${spot.y.toInt()} sold',
    const TextStyle(
    color: Colors.white,
    fontWeight: FontWeight.bold,
    ),
    );
    }).toList();
    },
    ),
    ),
    lineBarsData: [
    LineChartBarData(
    spots: categoryData.asMap().entries.map((entry) {
    return FlSpot(
    entry.key.toDouble(),
    (entry.value['totalQuantitySold'] as int).toDouble(),
    );
    }).toList(),
    isCurved: true,
    gradient: LinearGradient(colors: [themeColor, secondaryColor]),
    barWidth: 4,
    belowBarData: BarAreaData(
    show: true,
    gradient: LinearGradient(

      colors: [Color(0xFFB9644D).withOpacity(0.3), Color(0xFFDD9F78).withOpacity(0.3)],

    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    ),
    ),
    dotData: FlDotData(
    show: true,
    getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
    radius: 4,
    color: themeColor,
    strokeWidth: 2,
    strokeColor: Colors.white,
    ),
    ),
    ),
    ],
    titlesData: FlTitlesData(
    bottomTitles: AxisTitles(
    axisNameWidget: Padding(
    padding: const EdgeInsets.only(bottom: 0),
    child: Text(
    'Categories',
    style: TextStyle(
    color: Color(0xFFBE8261),
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    ),
    ),
    sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 60,
    interval: 1,
    getTitlesWidget: (value, meta) {
    int idx = value.toInt();
    if (idx >= 0 && idx < categoryData.length) {
    String category = categoryData[idx]['category'];
    if (category.length > 10) {
    category = category.substring(0, 10) + '..';
    }
    return Padding(
    padding: const EdgeInsets.only(top: 8.0),
    child: Transform.rotate(
    angle: -45 * 3.14159 / 180,
    child: Text(
    category,
    style: TextStyle(
    color: Color(0xFFBE8261),
    fontSize: 12,
    fontWeight: FontWeight.bold,
    ),
    textAlign: TextAlign.center,
    ),
    ),
    );
    }
    return Text('');
    },
    ),
    ),
    leftTitles: AxisTitles(
    axisNameWidget: Text(
    'Number Sold',
    style: TextStyle(
    color: Color(0xFFBE8261),
    fontSize: 13,
    fontWeight: FontWeight.bold,
    ),
    ),
    sideTitles: SideTitles(
    showTitles: true,
    reservedSize: 40,
    interval: 2,
    getTitlesWidget: (value, meta) => Text(
    value.toInt().toString(),
      style: TextStyle(color: themeColor, fontSize: 15),
    ),
    ),
    ),
      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.2),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> data, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(Icons.category, color: Color(0xFFBDA191), size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              data['category'],
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFFBDA191),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'Sold: ${data['totalQuantitySold']}',
            style: TextStyle(fontSize: 12, color: Color(0xFFC19C87),fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    return [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ][month - 1];
  }
}