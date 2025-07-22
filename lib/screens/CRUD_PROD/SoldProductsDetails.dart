import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class SoldProductsDetails extends StatefulWidget {
  final String ownerId;

  const SoldProductsDetails({required this.ownerId});

  @override
  _SoldProductsDetailsState createState() => _SoldProductsDetailsState();
}

class _SoldProductsDetailsState extends State<SoldProductsDetails> {
  List<dynamic> soldProductsData = [];
  bool isLoading = true;
  String? errorMessage;
  final primaryColor = const Color(0xFFA46145);
  final secondaryColor = const Color(0xFFC2A087);
  final backgroundColor = const Color(0xFFF5EEE9);

  @override
  void initState() {
    super.initState();
    _checkApiAndFetchData();
  }

  Future<void> _checkApiAndFetchData() async {
    final isApiAvailable = await _checkApiEndpoint();
    if (!isApiAvailable) {
      setState(() {
        errorMessage = 'Server is currently unavailable. Please try again later.';
        isLoading = false;
      });
      return;
    }
    _fetchSoldProducts();
  }

  Future<bool> _checkApiEndpoint() async {
    try {
      final testUrl = Uri.parse('http://vstore.runasp.net/api/HealthCheck');
      final response = await http.get(testUrl).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw 'Connection timeout',
      );
      return response.statusCode == 200;
    } catch (e) {
      print('API Check Error: $e');
      return false;
    }
  }

  Future<void> _fetchSoldProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url = Uri.parse('http://vstore.runasp.net/api/OwnerStatistics/sold-products/${widget.ownerId}');
      print('Fetching data from: $url');

      final response = await http.get(url, headers: {'accept': '*/*'})
          .timeout(const Duration(seconds: 10), onTimeout: () {
        throw 'Request timed out. Please check your connection.';
      });

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          setState(() {
            soldProductsData = data;
            isLoading = false;
          });
        } else {
          throw Exception('Expected list but got ${data.runtimeType}');
        }
      } else if (response.statusCode == 404) {
        throw Exception('The requested resource was not found (404)');
      } else {
        throw Exception('Server returned status code ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      _handleError('Network error: ${e.message}');
    } on FormatException catch (_) {
      _handleError('Invalid server response format.');
    } catch (e) {
      _handleError('Failed to load data: $e');
    }
  }

  void _handleError(String message) {
    print('Error: $message');
    setState(() {
      errorMessage = message;
      isLoading = false;
    });
    _showErrorSnackbar(message);
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: primaryColor,
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

  Map<String, dynamic>? get _mostSoldProduct {
    if (soldProductsData.isEmpty) return null;
    return soldProductsData.reduce((a, b) =>
    (a['totalQuantitySold'] as num) > (b['totalQuantitySold'] as num) ? a : b);
  }

  double get _maxChartValue {
    if (soldProductsData.isEmpty) return 20;
    final maxSold = soldProductsData
        .map((item) => (item['totalQuantitySold'] as num).toDouble())
        .reduce((a, b) => a > b ? a : b);
    return maxSold > 20 ? maxSold * 1.1 : 20;
  }

  List<FlSpot> get _chartSpots {
    return soldProductsData
        .asMap()
        .entries
        .map((entry) => FlSpot(
      entry.key.toDouble(),
      (entry.value['totalQuantitySold'] as num).toDouble(),
    ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundColor, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : errorMessage != null
                    ? _buildErrorState()
                    : soldProductsData.isEmpty
                    ? _buildEmptyState()
                    : SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        _buildTopProductCard(),
                        const SizedBox(height: 30),
                        _buildSalesChart(),
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
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, color: primaryColor, size: 22),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Best Selling Products',
            style: TextStyle(
              color: primaryColor,
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: primaryColor, size: 24),
            onPressed: _checkApiAndFetchData,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 20),
          Text(
            'Loading product data...',
            style: TextStyle(color: primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: primaryColor, size: 50),
          const SizedBox(height: 20),
          Text(
            'Unable to load data',
            style: TextStyle(
              color: primaryColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Text(
              errorMessage ?? 'Unknown error occurred',
              style: TextStyle(color: primaryColor.withOpacity(0.8), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _checkApiAndFetchData,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: primaryColor, size: 50),
          const SizedBox(height: 20),
          Text(
            'No sales data available',
            style: TextStyle(color: primaryColor, fontSize: 18),
          ),
          const SizedBox(height: 10),
          Text(
            'No products have been sold yet',
            style: TextStyle(color: secondaryColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [primaryColor, secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Icon(
                Icons.star_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'TOP SELLER',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _mostSoldProduct?['productName'] ?? 'N/A',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Sold: ',
                    style: TextStyle(
                      fontSize: 16,
                      color: secondaryColor,
                    ),
                  ),
                  TextSpan(
                    text: _formatLargeNumber(
                        (_mostSoldProduct?['totalQuantitySold'] as num?)?.toDouble() ?? 0),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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

  Widget _buildSalesChart() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SALES OVERVIEW',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: LineChart(
                  LineChartData(
                    minY: 0,
                    maxY: _maxChartValue,
                    lineBarsData: [
                      LineChartBarData(
                        spots: _chartSpots,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: primaryColor,
                        barWidth: 3,
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              secondaryColor.withOpacity(0.2),
                              Colors.transparent,
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 4,
                            color: primaryColor,
                            strokeWidth: 2,
                            strokeColor: secondaryColor,
                          ),
                        ),
                      ),
                    ],
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          interval: _maxChartValue > 20 ? _maxChartValue / 5 : 5,
                          getTitlesWidget: (value, meta) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Text(
                              _formatLargeNumber(value),
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < soldProductsData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  soldProductsData[index]['productName'] ?? 'N/A',
                                  style: TextStyle(
                                    color: secondaryColor,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _maxChartValue > 20 ? _maxChartValue / 5 : 5,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => primaryColor.withOpacity(0.8),
                        tooltipPadding: const EdgeInsets.all(8),
                        getTooltipItems: (touchedSpots) {
                          return touchedSpots.map((spot) {
                            final index = spot.x.toInt();
                            final productName = index < soldProductsData.length
                                ? soldProductsData[index]['productName'] ?? 'N/A'
                                : 'N/A';
                            return LineTooltipItem(
                              '$productName\n${_formatLargeNumber(spot.y)} sold',
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
            ),
          ],
        ),
      ),
    );
  }
}