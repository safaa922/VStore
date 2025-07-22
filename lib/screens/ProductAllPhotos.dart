import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class ProductAllPhotos extends StatefulWidget {
  final int prodId;

  ProductAllPhotos({required this.prodId});

  @override
  _ProductAllPhotosState createState() => _ProductAllPhotosState();
}

class _ProductAllPhotosState extends State<ProductAllPhotos> {
  late Future<List<Map<String, dynamic>>> productPhotos;

  @override
  void initState() {
    super.initState();
    productPhotos = fetchProductDetails(widget.prodId.toString());
  }


  Future<void> pickAndReplaceImage(int imageId) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      File selectedImage = File(image.path);
      await uploadImage(imageId, selectedImage);

      // Refresh the product images list after updating
      setState(() {
        productPhotos = fetchProductDetails(widget.prodId.toString());
      });
    }
  }

  Future<void> uploadImage(int imageId, File imageFile) async {
    try {
      var url = Uri.parse('http://vstore.runasp.net/api/owner/UpdateExistingImage/$imageId');
      print("Uploading image to: $url");

      var request = http.MultipartRequest('PUT', url); // Change POST to PUT if needed
      request.headers.addAll({
        'Authorization': 'Bearer YOUR_ACCESS_TOKEN',
      });

      request.files.add(await http.MultipartFile.fromPath('Photo', imageFile.path));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("Response Status: ${response.statusCode}");
      print("Response Body: $responseBody");

      if (response.statusCode == 200) {
        print("✅ Image updated successfully");
      } else {
        print("❌ Failed to upload image: ${response.reasonPhrase}");
      }
    } catch (e) {
      print("⚠️ Exception occurred while uploading image: $e");
    }
  }



  Future<List<Map<String, dynamic>>> fetchProductDetails(String productId) async {
    final response = await http.get(
      Uri.parse('http://vstore.runasp.net/api/Product/Get_Product_Details/$productId'),
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      print("📢 API Response: $data");

      if (data.containsKey('photos') && data['photos'] is List) {
        return List<Map<String, dynamic>>.from(
          data['photos'].where((item) => item is Map<String, dynamic> && item.containsKey('base64Photo')).map((item) {
            return {
              'id': item['imageId'] ?? 0,
              'base64Photo': item['base64Photo'],
            };
          }),
        );
      }
    }
    return [];
  }

  Uint8List? decodeBase64Image(String base64String) {
    try {
      base64String = base64String.replaceAll(RegExp(r'\s+'), '');
      return base64.decode(base64String);
    } catch (e) {
      print("⚠️ Error decoding base64 image: $e");
      return null;
    }
  }

  Future<void> setDefaultImage(BuildContext context, int productId, int imageId) async {
    try {
      if (imageId == 0 || imageId == null) {
        print("⚠️ Invalid image ID: $imageId. Cannot update default image.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("⚠️ Invalid image ID. Please try again."), backgroundColor: Colors.orange),
        );
        return;
      }

      var url = Uri.parse('http://vstore.runasp.net/api/owner/Replaceimage/$productId');
      print("🔄 Sending PATCH request to: $url with Image ID: $imageId");

      var request = http.MultipartRequest('PATCH', url)
        ..headers.addAll({
          'Authorization': 'Bearer YOUR_ACCESS_TOKEN', // Replace with actual token
        })
        ..fields['ImageId'] = imageId.toString(); // Ensure ImageId is properly sent

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        print("Default image updated successfully ✨");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Default image updated successfully! ✨",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            backgroundColor: Color(0xFFD7AC93),
          ),
        );

      } else {
        print("❌ Failed to update default image: ${response.statusCode} - $responseBody");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to update image. Try again."), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      print("⚠️ Exception while setting default image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Error: Something went wrong."), backgroundColor: Colors.red),
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
            color: Color(0xFFCE947D),
            fontWeight: FontWeight.w500,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 30.0),
          child: IconButton(
            icon: Icon(CupertinoIcons.left_chevron, color: Color(0xFFCE947D), size: 25),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: productPhotos,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final photos = snapshot.data!;

            return Padding(
              padding: EdgeInsets.all(10),
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  Uint8List? imageBytes = decodeBase64Image(photos[index]['base64Photo']);
                  int imageId = photos[index]['id'];

                  return Stack(
                    children: [
                      GestureDetector(
                        onTap: () => pickAndReplaceImage(imageId), // Allow picking a new image when tapped
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: imageBytes != null
                              ? Image.memory(imageBytes, fit: BoxFit.cover, width: double.infinity)
                              : Image.asset('assets/images/placeholder.png', fit: BoxFit.cover),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 5,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                            padding: EdgeInsets.all(5),
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                          ),
                          onPressed: () => setDefaultImage(context, widget.prodId, imageId),
                          child: Icon(Icons.star, color: Color(0xFFF1B780)),
                        ),
                      ),
                    ],
                  );

                },
              ),
            );
          } else {
            return Center(child: Text('No photos available'));
          }
        },
      ),
    );
  }
}