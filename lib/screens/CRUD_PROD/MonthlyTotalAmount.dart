import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MonthlyTotalAmountDetails extends StatefulWidget {
  final String ownerId;

  const MonthlyTotalAmountDetails({
    Key? key,
    required this.ownerId,
  }) : super(key: key);

  @override
  _MonthlyTotalAmountDetailsState createState() => _MonthlyTotalAmountDetailsState();
}

class _MonthlyTotalAmountDetailsState extends State<MonthlyTotalAmountDetails> {
  List<int> availableYears = [];
  int? selectedYear;
  int? selectedMonth;
  double? selectedMonthAmount;
  List<Map<String, dynamic>> monthlyRevenueData = [];
  bool isLoading = true;
  bool isLoadingYears = true;
  String? errorMessage;

  // Color scheme
  final primaryColor = const Color(0xFF6B705C);
  final secondaryColor = const Color(0xFFCB997E);
  final accentColor = const Color(0xFFD4A017);
  final backgroundColor = const Color(0xFFF8F1E9);
  final textColor = const Color(0xFF5D4037);

  @override
  void initState() {
    super.initState();
    _fetchAvailableYears();
  }

  Future<void> _fetchAvailableYears() async {
    setState(() {
      isLoadingYears = true;
      errorMessage = null;
    });

    try {
      final currentYear = DateTime
          .now()
          .year;
      final yearsToCheck = List.generate(5, (index) => currentYear - index);
      final yearsWithData = <int>[];

      for (final year in yearsToCheck) {
        final url = 'http://vstore.runasp.net/api/OwnerStatistics/monthly-revenue/${widget
            .ownerId}/$year';
        final response = await http.get(
            Uri.parse(url), headers: {'accept': '*/*'});

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as List;
          if (data.any((month) => (month['totalAmount'] as num) > 0)) {
            yearsWithData.add(year);
          }
        }
      }

      // Always include current year and previous year
      yearsWithData.add(currentYear);
      yearsWithData.add(currentYear - 1);

      // Remove duplicates and sort descending
      final uniqueYears = yearsWithData.toSet().toList()
        ..sort((a, b) => b.compareTo(a));

      setState(() {
        availableYears = uniqueYears;
        isLoadingYears = false;
        if (uniqueYears.isNotEmpty) {
          selectedYear = uniqueYears.first;
          _fetchMonthlyRevenueData();
        }
      });
    } catch (e) {
      setState(() {
        isLoadingYears = false;
        errorMessage = 'Failed to load available years: ${e.toString()}';
      });
      _showErrorSnackbar(errorMessage!);
    }
  }

  Future<void> _fetchMonthlyRevenueData() async {
    if (selectedYear == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
      selectedMonth = null;
      selectedMonthAmount = null;
    });

    try {
      final url = 'http://vstore.runasp.net/api/OwnerStatistics/monthly-revenue/${widget
          .ownerId}/$selectedYear';
      final response = await http.get(
          Uri.parse(url), headers: {'accept': '*/*'});

      if (response.statusCode == 200) {
        setState(() {
          monthlyRevenueData =
              (json.decode(response.body) as List).cast<Map<String, dynamic>>();
          isLoading = false;
        });
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Failed to load revenue data: ${e.toString()}';
      });
      _showErrorSnackbar(errorMessage!);
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(0xFFB0715F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  String _formatLargeNumber(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(0);
  }

  double get _totalRevenue {
    return monthlyRevenueData.fold(
      0.0,
          (sum, month) => sum + (month['totalAmount'] as num).toDouble(),
    );
  }

  double get _maxRevenue {
    if (monthlyRevenueData.isEmpty) return 100.0;
    final max = monthlyRevenueData
        .map((month) => (month['totalAmount'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return max * 1.2; // Add 20% padding
  }

  Map<int, double> get _revenueMap {
    return {
      for (var item in monthlyRevenueData)
        item['month'] as int: (item['totalAmount'] as num).toDouble()
    };
  }

  List<FlSpot> get _chartSpots {
    return List.generate(12, (index) {
      final month = index + 1;
      final revenue = _revenueMap[month] ?? 0.0;
      return FlSpot(index.toDouble(), revenue);
    });
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

          // Blur layer
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
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildYearSelector(),
                        const SizedBox(height: 20),
                        if (isLoadingYears)
                          _buildLoadingIndicator('Loading available years...'),
                        if (errorMessage != null && !isLoadingYears)
                          _buildErrorMessage(),
                        if (isLoading && selectedYear != null)
                          _buildLoadingIndicator('Loading revenue data...'),
                        if (selectedYear != null &&
                            monthlyRevenueData.isNotEmpty && !isLoading) ...[
                          _buildSummaryCards(),
                          const SizedBox(height: 20),
                          _buildRevenueChart(),
                        ],
                        if (selectedYear != null &&
                            monthlyRevenueData.isEmpty && !isLoading)
                          _buildNoDataMessage(),
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
                0xFFC47F69), size: 26),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Text(
              'Monthly Revenue',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFC47F69),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Color(0xFFC47F69), size: 26),
            onPressed: _fetchAvailableYears,
          ),
        ],
      ),
    );
  }

  Widget _buildYearSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Color(0xFFB96C57).withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFFCB816D), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedYear != null ? selectedYear.toString() : 'Select year',
                style: TextStyle(
                  color: selectedYear != null
                      ? Color(0xFFCB816D)
                      : Color(0xFFCB816D).withOpacity(0.7),
                  fontSize: 15,
                ),
              ),
            ),
            if (isLoadingYears)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: accentColor,
                  ),
                ),
              )
            else
              PopupMenuTheme(
                data: PopupMenuThemeData(
                  color: Colors.white, // 👈 Full white background
                  textStyle: TextStyle(
                    color: Color(0xFFCB816D),
                    fontSize: 16,
                  ),
                ),
                child: PopupMenuButton<int>(
                  icon: Icon(Icons.arrow_drop_down, color: Color(0xFFB0715F)),
                  onSelected: (int year) {
                    setState(() {
                      selectedYear = year;
                      _fetchMonthlyRevenueData();
                    });
                  },
                  itemBuilder: (BuildContext context) {
                    if (availableYears.isEmpty) {
                      return [
                        PopupMenuItem<int>(
                          value: null,
                          child: Text(
                            'No years available',
                            style: TextStyle(color: Color(0xFFB0715F)),
                          ),
                        ),
                      ];
                    }

                    return availableYears.map((int year) {
                      return PopupMenuItem<int>(
                        value: year,
                        child: Text(
                          year.toString(),
                          style: TextStyle(
                            color: Color(0xFFB0715F),
                            fontWeight: year == selectedYear
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFFCB816D)),
            const SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(color: Color(0xFFB0715F)),
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
            Icon(Icons.error_outline, color: Color(0xFFB0715F), size: 50),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _fetchAvailableYears,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
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
            Icon(Icons.money_off, color: accentColor, size: 50),
            const SizedBox(height: 16),
            Text(
              'No revenue data available for $selectedYear',
              style: TextStyle(color: textColor, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.monetization_on,
                title: 'Total Revenue',
                value: _formatLargeNumber(_totalRevenue),
                color: Color(0xFFE0A96E),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                icon: Icons.calendar_today,
                title: 'Year',
                value: selectedYear.toString(),
                color: Color(0xFFD2936C),
              ),
            ),
          ],
        ),
        if (selectedMonth != null) ...[
          const SizedBox(height: 12),
          _buildSummaryCard(
            icon: Icons.calendar_month,
            title: 'Month $selectedMonth Revenue',
            value: _formatLargeNumber(selectedMonthAmount ?? 0),
            color: Color(0xFFBD7762),
          ),
        ],
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.white,
      shadowColor: Color(0xFFB96F5A).withOpacity(0.2),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [

            Icon(icon, color: color, size: 21),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFB0715F),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 17,
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
        elevation: 4,
        shadowColor: const Color(0xFFBB705A).withOpacity(0.2),
    shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(20), // 👈 Match Card radius
    child: Container(
    color: Colors.white,
    height: 350,
    padding: const EdgeInsets.all(16),
    child: Column(
    children: [
    Text(
    'Monthly Revenue Trend',
    style: TextStyle(
    fontSize: 17,
    color: Color(0xFFD38D66),
    fontWeight: FontWeight.bold,
    ),
    ),
    const SizedBox(height: 16),
    Expanded(
    child: Padding(
    padding: const EdgeInsets.only(right: 12.0),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: _maxRevenue,
                    lineTouchData: LineTouchData(
                      enabled: true,
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (LineBarSpot spot) =>
                            primaryColor.withOpacity(0.8),
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              'Month ${spot.x.toInt() +
                                  1}\n${_formatLargeNumber(spot.y)}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      horizontalInterval: _maxRevenue > 100
                          ? _maxRevenue / 5
                          : 20,
                      verticalInterval: 1,
                      getDrawingHorizontalLine: (value) =>
                          FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                          ),
                      getDrawingVerticalLine: (value) =>
                          FlLine(
                            color: Colors.grey.withOpacity(0.1),
                            strokeWidth: 1,
                          ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            final month = value.toInt() + 1;
                            return Text(
                              month.toString(),
                              style: TextStyle(
                                color: Color(0xFFB4715D),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: _maxRevenue > 100 ? _maxRevenue / 5 : 20,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              _formatLargeNumber(value),
                              style: TextStyle(
                                color: Color(0xFFB4715D),
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: secondaryColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
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
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: secondaryColor,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    ),
    ),
    ],
    ),
    ),
    ),
    );
  }}