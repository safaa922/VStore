import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image/image.dart' as img;
import 'package:google_fonts/google_fonts.dart';
import 'Three_D.dart';


class TryOnPage extends StatefulWidget {
  final String productName;
  final String selectedImage;
  final String imageId;

  const TryOnPage({
    super.key,
    required this.selectedImage,
    required this.imageId,
    required this.productName,
  });

  @override
  _TryOnPageState createState() => _TryOnPageState();
}

class _TryOnPageState extends State<TryOnPage> {
  File? _userImage;
  bool _isLoading = false;
  String? _errorMessage;
  dynamic _resultImageBytes;
  String? _selectedCategory;

  final List<String> _tryOnCategories = ['upper_body', 'lower_body', 'dresses'];
  final int _maxRetries = 1;

  @override
  void initState() {
    super.initState();
    print('Image ID: ${widget.imageId}');
    print('Selected Image: ${widget.selectedImage.substring(
        0, min(50, widget.selectedImage.length))}...');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File originalImage = File(pickedFile.path);
      File? compressedImage = await _compressImage(originalImage);

      setState(() {
        _userImage = compressedImage ?? originalImage;
        _errorMessage = null;
      });
    }
  }

  Future<File?> _compressImage(File imageFile) async {
    try {
      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) {
        print('Failed to decode image for compression');
        return null;
      }

      final img.Image resizedImage = img.copyResize(image, width: 800);
      final List<int> compressedBytes = img.encodeJpg(resizedImage, quality: 85);

      final tempDir = Directory.systemTemp;
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      final originalSizeMB = (await imageFile.length()) / 1024 / 1024;
      final compressedSizeMB = (await tempFile.length()) / 1024 / 1024;
      print('Original Image Size: $originalSizeMB MB');
      print('Compressed Image Size: $compressedSizeMB MB');

      if (compressedSizeMB > 5) {
        print('Compressed image size exceeds 5MB limit');
        return null;
      }

      return tempFile;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<bool> _checkServerAvailability() async {
    try {
      print('Checking server availability...');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://vstore.runasp.net/api/TryOn/tryon/15'),
      );

      request.headers['Accept'] = 'application/json, image/*';
      request.headers['User-Agent'] = 'MyApp/1.0';

      request.fields['tryoncategory'] = 'upper_body';

      var streamedResponse = await request.send().timeout(Duration(seconds: 5));
      var response = await http.Response.fromStream(streamedResponse);

      print('Server Response Status: ${response.statusCode}');
      print(
          'Server Response Body: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');

      return response.statusCode != 0;
    } catch (e) {
      print('Server availability check failed: $e');
      if (e is SocketException) {
        print('SocketException Details: ${e.message}, OS Error: ${e.osError}');
      }
      return false;
    }
  }

  Future<void> _tryOnClothing() async {
    if (_userImage == null) {
      setState(() {
        _errorMessage = 'Please select an image first';
      });
      return;
    }

    if (_selectedCategory == null) {
      setState(() {
        _errorMessage = 'Please select a try-on category';
      });
      return;
    }

    int? parsedImageId = int.tryParse(widget.imageId);
    if (parsedImageId == null || parsedImageId <= 0) {
      setState(() {
        _errorMessage = 'Invalid product image selected for try-on';
      });
      return;
    }

    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          'Confirm Try-On',
          style: GoogleFonts.marmelad(
            color: const Color(
                0xFFC7836A),
            fontWeight: FontWeight.w600,
            fontSize: 20
          ),
        ),
        content: Text(
          'Are you sure you want to submit the request? Try-on uses limited resources.',
          style: TextStyle(
            color: const  Color(0xFFCE9B8B),
            fontSize: 16
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.roboto(
                color: const Color(0xFFC7836A),
                  fontSize: 15
              ),
            ),
          ),

          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Color(0xFFD7A08A),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              "Confirm",
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    if (!confirm) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resultImageBytes = null;
    });

    bool isServerAvailable = await _checkServerAvailability();
    if (!isServerAvailable) {
      setState(() {
        _errorMessage =
        'Cannot connect to the server. Please check your internet connection or try again later.';
        _isLoading = false;
      });
      return;
    }

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://vstore.runasp.net/api/TryOn/tryon/$parsedImageId'),
      );

      request.followRedirects = true;
      request.maxRedirects = 5;

      request.headers['Accept'] = 'application/json, image/*';
      request.headers['User-Agent'] = 'MyApp/1.0';

      var userImageFile =
      await http.MultipartFile.fromPath('UserImage', _userImage!.path);
      request.files.add(userImageFile);

      request.fields['tryoncategory'] = _selectedCategory!;

      print('Sending Try-On Request:');
      print('URL: ${request.url}');
      print('Image ID: $parsedImageId');
      print('TryOnCategory: $_selectedCategory');
      print('UserImage Path: ${_userImage!.path}');
      print('UserImage Size: ${(await _userImage!.length()) / 1024 / 1024} MB');
      print('Request Headers: ${request.headers}');
      print('Request Fields: ${request.fields}');

      var streamedResponse = await request.send().timeout(
        Duration(seconds: 300),
        onTimeout: () {
          throw TimeoutException('The Try-On request took too long.');
        },
      );
      var response = await http.Response.fromStream(streamedResponse);

      print('Try-On API Response Status: ${response.statusCode}');
      print('Try-On API Response Headers: ${response.headers}');
      print(
          'Try-On API Response Body: ${response.body.length > 100 ? response.body.substring(0, 100) + '...' : response.body}');

      if (response.statusCode == 200) {
        var contentType = response.headers['content-type'];
        print('Content-Type: $contentType');

        if (contentType != null && contentType.startsWith('image')) {
          setState(() {
            _resultImageBytes = response.bodyBytes;
          });
        } else if (contentType != null &&
            contentType.contains('application/json')) {
          try {
            String base64Image = response.body;
            base64Image = base64Image.trim();
            base64Image = base64Image.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
            if (base64Image.contains(',')) {
              base64Image = base64Image.split(',').last;
            }

            if (base64Image.isEmpty || base64Image.length < 100) {
              setState(() {
                _errorMessage = 'Invalid image data received';
              });
            } else {
              setState(() {
                _resultImageBytes = base64Decode(base64Image);
              });
            }
          } catch (e) {
            setState(() {
              _errorMessage = 'Failed to decode image: $e';
            });
            print('Base64 Decode Error: $e');
          }
        } else {
          setState(() {
            _errorMessage = 'Unexpected Content-Type: $contentType';
          });
        }
      } else {
        if (response.statusCode == 429 ||
            (response.statusCode == 400 &&
                response.body.contains('429 Too Many Requests'))) {
          setState(() {
            _errorMessage =
            'Too many requests. Please wait a few minutes and try again.';
          });
        } else {
          try {
            var jsonResponse = jsonDecode(response.body);
            setState(() {
              _errorMessage = jsonResponse['error'] ??
                  'Request failed with status ${response.statusCode}';
            });
          } catch (e) {
            setState(() {
              _errorMessage = 'Request failed: ${response.body}';
            });
          }
        }
      }
    } catch (e) {
      print('Try-On API Error: $e');
      if (e is SocketException) {
        setState(() {
          _errorMessage =
          'Connection error: The server closed the connection unexpectedly. Please check your internet or try again later.';
        });
      } else if (e is TimeoutException) {
        setState(() {
          _errorMessage =
          'Request timed out after 5 minutes. The server might be busy. Please try again later.';
        });
      } else {
        setState(() {
          _errorMessage = 'An error occurred: ${e.toString()}';
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Virtual Try On',
          style: GoogleFonts.playfairDisplay(
            color: Color(0xFFC7836A),
            fontWeight: FontWeight.bold,
            fontSize: 21,
          ),
        ),
        centerTitle: true, // ✅ This centers the title
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20.0, right: 0),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_outlined, color: Color(0xFFC7836A)),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        toolbarHeight: 70,
      ),

      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26.0, vertical: 30.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AnimatedOpacity(
                opacity: _userImage == null ? 1.0 : 1.0,
                duration: const Duration(milliseconds: 500),
                child: Container(
                  decoration: BoxDecoration(
                    color: Color(0xFFF6EBE4),
                    borderRadius: BorderRadius.circular(16),

                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          base64Decode(
                            widget.selectedImage.contains(',')
                                ? widget.selectedImage.split(',').last
                                : widget.selectedImage,
                          ),
                          width: 180,
                          height: 220,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            print('Image Decode Error: $error');
                            return Column(
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: const Color(0xFFC77263),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Failed to load product image',
                                  style: TextStyle(
                                    color: const Color(0xFFC77263),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),

                    ],
                  ),
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        // Background Image Container
                        Container(
                          height: 70,
                          width: 470,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/InputBorder4_enhanced.png'),
                              fit: BoxFit.fill,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),

                        // Optional placeholder if _selectedCategory is null
                        if (_selectedCategory == null)
                          Positioned(
                            left: 20,
                            child: Text(
                              'Select Category',
                              style: TextStyle(
                                color: Color(0xFFD0967E),
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                        // Dropdown
                        Container(
                          height: 26,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategory,
                              decoration: const InputDecoration.collapsed(hintText: ''),
                              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFD09E89)),
                              dropdownColor: Colors.white,
                              style: GoogleFonts.roboto(
                                color: Color(0xFFD09E89),
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              items: _tryOnCategories.map((String category) {
                                return DropdownMenuItem<String>(
                                  value: category,
                                  child: Align(
                                    alignment: Alignment.centerLeft, // Center left inside the row
                                    child: Text(
                                      category.replaceAll('_', ' ').toUpperCase(),
                                      style: TextStyle(
                                        color: Color(0xFFD09E89),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        height: 1, // ✅ Helps with vertical centering
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedCategory = newValue;
                                });
                              },
                              validator: (value) =>
                              value == null ? 'Please select a category' : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),



              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD08A76),Color(0xFFEFC4AB)], // Replace with your colors
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),

                ),
                child: ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.camera_alt_rounded, size: 23, color: Colors.white),
                  label: Text(
                    'Select an image of you',
                    style: GoogleFonts.marmelad(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              if (_userImage != null)
                AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 500),
                  child: Container(
                    padding: const EdgeInsets.all(2), // Thickness of the border
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDE9B88),Color(0xFFFFDDCA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(
                        _userImage!,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              if (_userImage != null)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD08A76),Color(0xFFEFC4AB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),


                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _tryOnClothing,
                    child: _isLoading
                        ? const SpinKitFadingFour(
                      color: Colors.white,
                      size: 28,
                    )
                        : Text(
                      'Try On Now',
                      style: GoogleFonts.marmelad(
                        fontSize: 17,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFFFEFE9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFD26147)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.roboto(
                              color: Color(0xFFD26147),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        const SpinKitFadingFour(
                          color: Color(0xFFBE7D61),
                          size: 40,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Processing your try-on... This may take a few minutes.',
                          style: GoogleFonts.roboto(
                            color: Color(0xFFBE7D61),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_resultImageBytes != null)
                Column(
                  children: [
                    Text(
                      'Your Look :',
                      style: GoogleFonts.marmelad(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFE4A48D),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedOpacity(
                      opacity: 1.0,
                      duration: const Duration(milliseconds: 500),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFF9E4E4),
                            width: 2,
                          ),

                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _resultImageBytes,
                            height: 320,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Text(
                                'Failed to display image',
                                style: GoogleFonts.roboto(
                                  color: const Color(0xFFBE7D61),
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD08A76),Color(0xFFEFC4AB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),

                      ),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThreeDViewPage(
                                resultImageBytes: _resultImageBytes,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.threed_rotation,
                          size: 24,
                          color: Colors.white,
                        ),
                        label: Text(
                          'Try 3D Now',
                          style: GoogleFonts.marmelad(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 103),
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }


}