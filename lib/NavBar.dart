import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class CustomBottomNavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  final String userId;

  CustomBottomNavBar({
    required this.selectedIndex,
    required this.onItemTapped,
    required this.userId,
  });

  @override
  _NavBarUserState createState() => _NavBarUserState();
}

class _NavBarUserState extends State<CustomBottomNavBar> {
  int notificationCount = 0;

  @override
  void initState() {
    super.initState();
    fetchNotificationCount();
  }

  Future<void> fetchNotificationCount() async {
    try {
      final response = await Dio().get('http://vstore.runasp.net/api/Notifications/GetNumOfNotifi/${widget.userId}');
      if (response.statusCode == 200) {
        final count = response.data; // العدد يعود مباشرةً في response.data
        setState(() {
          notificationCount = count;
          print("Notification Count Updated: $notificationCount");
        });
      } else {
        print("Failed to fetch notifications count: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching notifications count: $e");
    }
  }

  Future<void> clearNotifications() async {
    try {
      final response = await Dio().patch(
        'http://vstore.runasp.net/api/Notifications/readNotifications/${widget.userId}',
        options: Options(
          headers: {
            'accept': 'charset=utf-8 ', // إضافة الهيدر المطلوب
          },
        ),
      );

      if (response.statusCode == 200) {
        print("Notifications marked as read: ${response.data}");
        setState(() {
          notificationCount = 0; // تصفير العدد يدويًا
        });
        await fetchNotificationCount(); // إعادة جلب عدد الإشعارات للتأكد
      } else {
        print("Failed to clear notifications: ${response.statusCode}");
      }
    } catch (e) {
      print("Error clearing notifications: $e");
    }
  }

  Widget _buildNavBarIcon(IconData iconData, bool isSelected, {bool showBadge = false}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        isSelected
            ? Container(
          padding: EdgeInsets.all(1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withOpacity(0.3),
                blurRadius: 5.0,
                spreadRadius: 1.0,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: Icon(iconData, color: Colors.white, size: 29),
        )
            : Icon(iconData, color: Colors.white, size: 29),
        if (showBadge && notificationCount > 0) // عرض البادج فقط إذا كان notificationCount أكبر من 0
          Positioned(
            right: -5,
            top: -5,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red, // لون البادج
                shape: BoxShape.circle,
              ),
              constraints: BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                '$notificationCount', // عرض العدد
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(35),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0.09),
      decoration: BoxDecoration(
        color: Color(0xFFD7B4A1),
        borderRadius: BorderRadius.circular(46),
      ),
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        items: [
          BottomNavigationBarItem(
            icon: _buildNavBarIcon(Icons.home, widget.selectedIndex == 0),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: _buildNavBarIcon(Icons.bar_chart, widget.selectedIndex == 1),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: GestureDetector(
              onTap: () async {
                print("Clearing notifications...");
                await clearNotifications();
                widget.onItemTapped(2);
              },
              child: _buildNavBarIcon(Icons.notifications, widget.selectedIndex == 2, showBadge: true),
            ),
            label: '',
          ),

          BottomNavigationBarItem(
            icon: _buildNavBarIcon(Icons.person, widget.selectedIndex == 4),
            label: '',
          ),
        ],
        currentIndex: widget.selectedIndex,
        onTap: widget.onItemTapped,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        iconSize: 28,
      ),
    );
  }
}