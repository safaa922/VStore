import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data'; // لاستخدام Uint8List
import 'package:shared_preferences/shared_preferences.dart';

class Notificationsuser extends StatelessWidget {
  final String userId;

  Notificationsuser({required this.userId});

  Future<String?> getUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('id'); // Retrieve the 'id' from SharedPreferences
  }

  Future<List<dynamic>> fetchNotifications() async {
    final response = await http.get(Uri.parse('http://vstore.runasp.net/api/Notifications/getnotifications/signalr/$userId'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['notifications']; // نعود بقائمة الإشعارات
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        backgroundColor: Color(0xFFB0715F),
        elevation: 4,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        toolbarHeight: 80,
      ),
      backgroundColor: Colors.white,
      body: FutureBuilder<List<dynamic>>(
        future: fetchNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('No Notifications yet' ,style: TextStyle(color:Color(0xFFB0735A)),));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/NotifiPng.png', // 👈 Replace with your image path
                    width: 180,
                    height: 170,
                  ),
                  SizedBox(height: 16), // space between image and text
                  Text(
                    'No Notifications yet',
                    style: TextStyle(
                      color: Color(0xFFB0735A),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }
          else {
            final notifications = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.all(4.0),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
                final isRead = notification['isread'] ?? false;
                final imageBase64 = notification['image']; // البيانات المرمَّزة Base64
                final message = notification['body'] ?? 'No message';
                final shortMessage = message.length > 50 ? '${message.substring(0, 50)}...' : message;

                // فك تشفير الصورة إذا كانت متوفرة
                Uint8List? imageBytes;
                if (imageBase64 != null && imageBase64.isNotEmpty) {
                  try {
                    imageBytes = base64Decode(imageBase64);
                  } catch (e) {
                    print('Failed to decode image: $e');
                  }
                }

                return NotificationCard(
                  isRead: isRead,
                  imageBytes: imageBytes, // استخدام Uint8List بدلاً من URL
                  title: notification['title'] ?? 'No title',
                  shortMessage: shortMessage,
                  date: notification['dateTime'] ?? 'No date',
                  fullMessage: message,
                  onTap: () {
                    _showMessageDialog(context, message, imageBytes);
                  },
                );
              },
            );
          }
        },
      ),
    );
  }

  void _showMessageDialog(BuildContext context, String message, Uint8List? imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageBytes != null)
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: MemoryImage(imageBytes),
                  ),
                SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.brown[800],
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFB0715F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class NotificationCard extends StatelessWidget {
  final bool isRead;
  final Uint8List? imageBytes; // استخدام Uint8List لعرض الصورة
  final String title;
  final String shortMessage;
  final String date;
  final String fullMessage;
  final VoidCallback onTap;

  NotificationCard({
    required this.isRead,
    required this.imageBytes,
    required this.title,
    required this.shortMessage,
    required this.date,
    required this.fullMessage,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isRead ? Colors.white : Colors.grey[200], // تمييز الرسائل غير المقروءة
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      elevation: 3,
      shadowColor: Color(0xFF2F1E58).withOpacity(0.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.zero,
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(60),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: imageBytes != null
                    ? CircleAvatar(
                  radius: 18,
                  backgroundImage: MemoryImage(imageBytes!), // عرض الصورة من Uint8List
                )
                    : CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFB0715F),
                  child: Icon(Icons.notifications, color: Colors.white, size: 16),
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFB0715F),
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shortMessage,
                      style: TextStyle(fontSize: 11, color: Colors.brown[600]),
                    ),
                    SizedBox(height: 3),
                    Text(
                      date,
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}