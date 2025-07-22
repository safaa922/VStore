import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;

import '../../constants.dart';
import '../OwnerDashBoard.dart';

class ProdPhotos extends StatefulWidget {
  final Map<String, dynamic> productData;
  final String userId;


  const ProdPhotos({Key? key, required this.productData,required this.userId}) : super(key: key);

  @override
  _ProdPhotosState createState() => _ProdPhotosState();
}

Future<String?> getOwnerId() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  final ownerId = prefs.getString('id');
  print('OwnerId from SharedPreferences: $ownerId');
  return ownerId;
}

class _ProdPhotosState extends State<ProdPhotos> {
  File? _productPhoto;

  Future<File> resizeImage(File file) async {
    final bytes = await file.readAsBytes();
    final originalImage = img.decodeImage(bytes);
    if (originalImage == null) {
      throw Exception('Unable to decode image');
    }

    final resized = img.copyResize(originalImage, width: 800);
    final resizedBytes = img.encodeJpg(resized, quality: 70);

    // Save as .jpg to a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempFile.writeAsBytes(resizedBytes);

    return tempFile;
  }

  // Select the product photo
  Future<void> _pickProductPhoto() async {
    final pickedFile = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Reduces size
    );
    if (pickedFile != null) {
      String extension = pickedFile.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png', 'tif'].contains(extension)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only JPG, PNG, or TIF images are allowed.')),
        );
        return;
      }

      File resized = await resizeImage(File(pickedFile.path));
      setState(() {
        _productPhoto = resized;
      });
    }
  }


  // Submit the product with the selected photo
  Future<void> _submitProduct() async {
    if (_productPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a product photo')),
      );
      return;
    }

    try {
      final productId = await _addProductPhoto();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product uploaded successfully! ID: $productId')),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OwnerDashboard(userId: widget.userId), // Fix: use widget.productData
        ),
      );


    } catch (e) {
      print('Error submitting product: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit product')),
      );
    }
  }

  Future<String> _addProductPhoto() async {
    final ownerId = await getOwnerId();
    if (ownerId == null) {
      throw Exception('Owner ID not found in shared preferences');
    }

    final url = Uri.parse('http://vstore.runasp.net/api/Product/AddProduct/$ownerId');
    final request = http.MultipartRequest('POST', url);

    // Add product details
    widget.productData.forEach((key, value) {
      if (value != null) {
        request.fields[key] = value.toString();
      }
    });

    // Add the product photo as a multipart file
    if (_productPhoto != null) {
      request.files.add(
        await http.MultipartFile.fromPath('Photo', _productPhoto!.path),
      );
    }

    // Debugging: Log the request details before sending
    print('Request Details:');
    print('URL: $url');
    print('Fields: ${request.fields}');

    try {
      // Send the request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      print('Response Status: ${response.statusCode}');
      print('Response Body: $responseBody');

      // Handle non-JSON response (plain text)
      if (response.statusCode == 200) {
        if (responseBody.contains('Product Added Successfully')) {
          return 'Product Added Successfully';
        } else {
          final data = json.decode(responseBody);
          return data['productId'];
        }
      } else {
        print('Failed to upload product photo: ${response.statusCode}');
        throw Exception('Failed to upload product photo: $responseBody');
      }
    } catch (e) {
      print('Error occurred: $e');
      throw Exception('Failed to upload product photo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title:  Text(
          'Product Photo',
          style: TextStyle(
            color: Color(0xFFCE967F),
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 30.0), // Adjust this value to move the arrow to the right
          child: IconButton(
            icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFCE947C), size: 25),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top:70.0),
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
                _productPhoto != null
                    ? Text(
                  'Product Photo: ${_productPhoto!.path.split('/').last}',
                  style: TextStyle(
                    color: Color(0xFFD2A793),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                )
                    : Text(
                  'Select a Product Photo',
                  style: TextStyle(
                    color: Color(0xFFCEA491),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                if (_productPhoto == null)
                ElevatedButton(
                  onPressed: _pickProductPhoto,
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
                          'Choose an Image',
                          style: TextStyle(
                            color: Color(0xFFCE9780),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.camera_alt, color: Color(0xFFD29A83), size: 28),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 18),
                SizedBox(
                  width: 260, // Make it take full width
                  height: 54, // Adjust height
                  child: ElevatedButton(
                    onPressed: _submitProduct,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFE0A486), // Set background color
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Optional: rounded corners
                      ),
                    ),
                    child: Text(
                      'Submit Product',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600 , color: Colors.white), // Optional: improve text style
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

}
