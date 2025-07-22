import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class OwnerStatisticsDetails extends StatefulWidget {
  final String ownerId;

  const OwnerStatisticsDetails({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  _OwnerStatisticsDetailsState createState() => _OwnerStatisticsDetailsState();
}

class _OwnerStatisticsDetailsState extends State<OwnerStatisticsDetails> {
  int? selectedYear;
  List<Map<String, dynamic>> monthlyOrders = [];
  List<int> availableYears = [];
  bool isLoading = false;
  String? errorMessage;
  bool hasData = false;
  bool yearSelected = false;

  // Color scheme
  final primaryColor = const Color(0xFF8D552F);
  final secondaryColor = const Color(0xFFB0715F);
  final accentColor = const Color(0xFFDFB7A1);
  final backgroundColor = const Color(0xFFF8F1E9);
  final textColor = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _initializeYears();
  }

  void _initializeYears() {
    // تحديد السنوات المتاحة يدوياً (السنة الحالية والسنة السابقة)
    final currentYear = DateTime.now().year;
    setState(() {
      availableYears = [currentYear, currentYear - 1];
    });
  }

  Future<void> _fetchOrdersData() async {
    if (selectedYear == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      hasData = false;
    });

    try {
      final url = 'http://vstore.runasp.net/api/OwnerStatistics/orders-per-month/${widget.ownerId}/$selectedYear';
      final response = await http.get(Uri.parse(url), headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        setState(() {
          monthlyOrders = data.cast<Map<String, dynamic>>();
          isLoading = false;
          hasData = monthlyOrders.isNotEmpty;
          yearSelected = true;
          if (!hasData) {
            errorMessage = 'No order data available for $selectedYear';
          }
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load order data: ${e.toString()}';
      });
      _showErrorSnackbar(errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: secondaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // باقي الدوال كما هي (getters للطلبات والحد الأقصى)
  int get _totalOrders {
    return monthlyOrders.fold(0, (sum, month) => sum + (month['orderCount'] as int));
  }

  double get _maxOrderCount {
    if (monthlyOrders.isEmpty) return 100;
    final max = monthlyOrders
        .map((month) => (month['orderCount'] as int).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max * 1.2;
  }



  @override
  Widget build(BuildContext context) {
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


          // Foreground UI
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildYearSelector(),
                        const SizedBox(height: 24),
                        if (yearSelected) ...[
                          if (isLoading)
                            _buildLoadingIndicator(),
                          if (errorMessage != null && !isLoading)
                            _buildErrorMessage(),
                          if (hasData && !isLoading) ...[
                            _buildChart(),
                            const SizedBox(height: 24),
                            _buildTotalOrdersCard(),
                          ],
                          if (!hasData && !isLoading)
                            _buildNoDataMessage(),
                        ] else ...[
                          _buildYearSelectionPrompt(),
                        ],
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


  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined, color: Color(
                0xFFC47F69), size: 24),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Monthly Orders',
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
            icon: Icon(Icons.refresh, color: Color(0xFFC47F69), size: 25),
            onPressed: () {
              if (selectedYear != null) {
                _fetchOrdersData();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return GestureDetector(
      onTap: () {
        if (availableYears.isNotEmpty) {
          _showYearSelectionDialog();
        }
      },
      child: Container(
        height: 50,

        padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [

            BoxShadow(
              color: Color(0xFFB96C57).withOpacity(0.2),
              blurRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(
              'Select Year:',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFB0715F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              selectedYear?.toString() ?? 'Choose year',
              style: TextStyle(
                color: selectedYear != null ? Color(0xFFB0715F) : Color(0xFFB0715F).withOpacity(0.8),
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_drop_down, color: primaryColor),
          ],
        ),
      ),
    );
  }

  void _showYearSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.white.withOpacity(1),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Year',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFDA9785),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  width: 100,
                  child: ListView.builder(
                    itemCount: availableYears.length,
                    itemBuilder: (context, index) {
                      final year = availableYears[index];
                      return ListTile(
                        title: Text(
                          year.toString(),
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFFB4796A),
                          ),
                        ),
                        onTap: () {
                          setState(() {
                            selectedYear = year;
                            yearSelected = true;
                          });
                          Navigator.pop(context);
                          _fetchOrdersData();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // باقي ويدجت البناء كما هي (_buildLoadingIndicator, _buildErrorMessage, ...)
  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryColor),
            const SizedBox(height: 20),
            Text(
              'Loading order data...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearSelectionPrompt() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(29),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 50, color: Color(0xFFCB816D)),
            const SizedBox(height: 20),
            Text(
              'Please select a year to view statistics',
              style: TextStyle(
                fontSize: 15,
                color: Color(0xFFA26853).withOpacity(0.7),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Color(0xFFC4725C), size: 50),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchOrdersData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFCB816D),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_empty, color: Color(0xFFD79967), size: 50),
            const SizedBox(height: 16),
            Text(
              'No order data available for $selectedYear',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Container(
      height: 350,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB0715F).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Monthly Order Trend',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFFB97962).withOpacity(0.8),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: _maxOrderCount,
                lineBarsData: [
                  LineChartBarData(
                    spots: monthlyOrders.asMap().entries.map((entry) {
                      return FlSpot(
                        entry.key.toDouble(),
                        (entry.value['orderCount'] as int).toDouble(),
                      );
                    }).toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: Color(0xFFD29072),
                    barWidth: 3,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFA94C33).withOpacity(0.3),
                          Color(0xFFD57E46).withOpacity(0.1),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Color(0xFFD9906F),
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    axisNameWidget: Padding(
                      padding: const EdgeInsets.only(top: 0),
                      child: Text(
                        'Months',
                        style: TextStyle(
                          color: Color(0xFFC78967),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        final month = value.toInt() + 1;
                        return Text(
                          month.toString(),
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: Text(
                      'Orders',
                      style: TextStyle(
                        color: Color(0xFFC78967),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 20, // Distribute numbers every 20 units up to 100
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: textColor.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 20, // Horizontal lines every 20 units
                  verticalInterval: 1,    // Vertical line for each month
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                  getDrawingVerticalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineTouchData: LineTouchData(
                  enabled: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => primaryColor.withOpacity(0.8),
                    tooltipPadding: const EdgeInsets.all(8),
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final month = spot.x.toInt() + 1;
                        return LineTooltipItem(
                          'Month $month\n${spot.y.toInt()} orders',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalOrdersCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFB0715F).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
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
                colors: [Color(0xFFBF6D56), Color(0xFFDD9F78)],
              ),
            ),
            child: Icon(
              Icons.shopping_bag,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Orders in $selectedYear',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFFC7987D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _totalOrders.toString(),
                style: TextStyle(
                  fontSize: 26,
                  color: Color(0xFFC78967),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}