import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:virtual_store/screens/Login.dart';

class LocationPickerScreen extends StatefulWidget {
  final String userId;

  LocationPickerScreen({required this.userId});

  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng? pickedLocation;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExistingLocation();
  }

  Future<void> _loadExistingLocation() async {
    final url = Uri.parse('http://vstore.runasp.net/api/Location/${widget.userId}');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double latitude = data['latitude'];
        final double longitude = data['longitude'];

        setState(() {
          pickedLocation = LatLng(latitude, longitude);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        // No location found or error; allow new one
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error fetching location: $e");
    }
  }

  Future<void> _sendLocationToAPI(LatLng location) async {
    final url = Uri.parse('http://vstore.runasp.net/api/Location');
    final body = jsonEncode({
      "userId": widget.userId,
      "latitude": location.latitude,
      "longitude": location.longitude,
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location saved successfully!')),
      );

      // Wait for the snackbar to show briefly, then navigate
      await Future.delayed(Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save location.')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pick your Location',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Color(0xFFE1AA92).withOpacity(0.9),
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
        toolbarHeight: 65,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : FlutterMap(
        options: MapOptions(
          center: pickedLocation ?? LatLng(30.0444, 31.2357), // default to Cairo
          zoom: 13.0,
          onTap: (tapPosition, point) {
            setState(() {
              pickedLocation = point;
            });
          },
        ),
        children: [
          TileLayer(
            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
            userAgentPackageName: 'com.example.app',
          ),
          if (pickedLocation != null)
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: pickedLocation!,
                  child: Icon(Icons.location_pin, size: 40, color: Colors.red),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: pickedLocation != null
          ? FloatingActionButton(
        onPressed: () => _sendLocationToAPI(pickedLocation!),
        backgroundColor: Color(0xFFDE7861), // 🔴 Make the button red
        child: Icon(Icons.check, color: Colors.white), // Optional: make icon white for better contrast
        tooltip: 'Save Location',
      )
          : null,

    );
  }
}
