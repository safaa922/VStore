import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../OwnerDashBoard.dart';

class Product_Additional_Photos extends StatefulWidget {
  final int Prod_id;

  const Product_Additional_Photos({Key? key, required this.Prod_id}) : super(key: key);

  @override
  _ProdPhotosState createState() => _ProdPhotosState();
}

class _ProdPhotosState extends State<Product_Additional_Photos> {
  List<File> _productPhotos = []; // Store multiple selected photos

  // Select multiple product photos
  Future<void> _pickProductPhotos() async {
    final pickedFiles = await ImagePicker().pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        _productPhotos = pickedFiles.map((file) => File(file.path)).toList();
      });
    }
  }

  // Submit multiple product photos
  Future<void> _addProductPhotos() async {
    if (_productPhotos.isEmpty) {
      print('DEBUG: No images selected.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    final url = Uri.parse('http://vstore.runasp.net/api/Owner/AddMulti-Images/${widget.Prod_id}');
    print('DEBUG: Uploading to URL: $url');

    var request = http.MultipartRequest('POST', url);

    // Add headers
    request.headers.addAll({
      "Accept": "application/json",
    });

    print('DEBUG: Headers set - ${request.headers}');

    // Attach image files
    for (var photo in _productPhotos) {
      print('DEBUG: Attaching file - ${photo.path}');
      request.files.add(
        await http.MultipartFile.fromPath('NewPhotos', photo.path),
      );
    }

    try {
      print('DEBUG: Sending request...');
      var response = await request.send();

      print('DEBUG: Response status - ${response.statusCode}');
      print('DEBUG: Response headers - ${response.headers}');

      var responseBody = await response.stream.bytesToString();
      print('DEBUG: Response body - $responseBody');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Photos uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${response.reasonPhrase}')),
        );
      }
    } catch (error) {
      print('DEBUG: Request failed - $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Product Photos',
          style: TextStyle(
            color: Color(0xFFD09E89),
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: IconButton(
            icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFD09E89), size: 25),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 70.0),
            child: Center(
              child: Image.asset(
                'assets/images/Camera4Png.png',
                width: 230,
                height: 230,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(1.0),
            child: Column(
              children: [
                _productPhotos.isNotEmpty
                    ? Column(
                  children: _productPhotos.map((photo) {
                    return Text(
                      'Photo: ${photo.path.split('/').last}',
                      style: TextStyle(
                        color: Color(0xFFCFAD9D),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    );
                  }).toList(),
                )
                    : Text(
                  'Select Product Photos',
                  style: TextStyle(
                    color: Color(0xFFCFAD9D),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                ElevatedButton(
                  onPressed: _pickProductPhotos,
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 7, horizontal: 80),
                    backgroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Container(
                    height: 66,
                    decoration: BoxDecoration(
                      border: Border.all(width: 3, color: Colors.transparent),
                      image: DecorationImage(
                        image: AssetImage('assets/images/InputBorder4_enhanced.png'),
                        fit: BoxFit.fill,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 10),
                        Text(
                          'Choose Images',
                          style: TextStyle(
                            color: Color(0xFFD09E89),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.camera_alt, color: Color(0xFFD09E89), size: 28),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: 260,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _addProductPhotos,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFDAA990),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'Submit Product',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
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
}
