import 'package:flutter/material.dart';

class successfulPayment extends StatelessWidget {
  final String? sessionId;

  const successfulPayment({Key? key, this.sessionId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 120),
              SizedBox(height: 24),
              Text(
                "Payment Successful!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),
              Text(
                "Thank you for your purchase.",
                style: TextStyle(fontSize: 18, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
              if (sessionId != null) ...[
                SizedBox(height: 24),
                Text(
                  "Session ID:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                SelectableText(
                  sessionId!,
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
                child: Text("Back to Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  textStyle: TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
