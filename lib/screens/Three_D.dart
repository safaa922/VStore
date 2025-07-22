import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ThreeDViewPage extends StatefulWidget {
  final dynamic resultImageBytes;

  const ThreeDViewPage({super.key, required this.resultImageBytes});

  @override
  _ThreeDViewPageState createState() => _ThreeDViewPageState();
}

class _ThreeDViewPageState extends State<ThreeDViewPage> {
  bool _isLoading = false;
  String? _errorMessage;
  String? _modelUrl;
  late http.Client _httpClient;
  DateTime? _lastRequestTime;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
  }

  @override
  void dispose() {
    _httpClient.close();
    super.dispose();
  }

  Future<bool> _isUrlAccessible(String url) async {
    try {
      print('Checking accessibility of model URL: $url');
      final response = await _httpClient
          .head(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      print('URL accessibility check result: ${response.statusCode}');
      return response.statusCode == 200;
    } on TimeoutException {
      print('URL check timed out');
      return false;
    } catch (e) {
      print('Error checking URL accessibility: $e');
      return false;
    }
  }

  bool _canSendRequest() {
    if (_lastRequestTime == null) {
      return true;
    }
    final elapsed = DateTime.now().difference(_lastRequestTime!);
    final canSend = elapsed.inMinutes >= 5;
    if (!canSend) {
      setState(() {
        _errorMessage =
        'Too many requests. Please wait ${5 - elapsed.inMinutes} minute(s) and try again.';
      });
    }
    return canSend;
  }

  Future<void> _generate3DModel() async {
    if (!_canSendRequest()) {
      return;
    }

    if (widget.resultImageBytes == null || widget.resultImageBytes.isEmpty) {
      setState(() {
        _errorMessage = 'No valid try-on result available for 3D generation';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _modelUrl = null;
    });

    File? tempFile;
    int retryCount = 0;
    const maxRetries = 0;

    while (retryCount <= maxRetries) {
      try {
        _lastRequestTime = DateTime.now();
        print('Starting 3D Generation Request at: $_lastRequestTime (Attempt ${retryCount + 1})');

        // Create temporary file
        final tempDir = Directory.systemTemp;
        tempFile = File(
            '${tempDir.path}/tryon_result_${DateTime.now().millisecondsSinceEpoch}.jpg');

        // Check if file can be created
        try {
          await tempFile.writeAsBytes(widget.resultImageBytes);
        } catch (e) {
          setState(() {
            _errorMessage = 'Failed to create temporary file: $e';
            _isLoading = false;
          });
          return;
        }

        final fileSizeMB = (await tempFile.length()) / 1024 / 1024;
        if (fileSizeMB > 5) {
          setState(() {
            _errorMessage =
            'Image size too large (${fileSizeMB.toStringAsFixed(2)} MB). Maximum is 5 MB.';
            _isLoading = false;
          });
          return;
        }

        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://vstore.runasp.net/api/Hunyuan3D/generate3D'),
        );

        request.headers['Accept'] = 'application/json';
        request.headers['User-Agent'] = 'MyApp/1.0';

        var imageFile = await http.MultipartFile.fromPath('ImageFile', tempFile.path);
        request.files.add(imageFile);
        request.fields['ImageUrl'] = '';

        print('Sending 3D Generation Request:');
        print('URL: ${request.url}');
        print('Headers: ${request.headers}');
        print('Fields: ${request.fields}');
        print('File: ${tempFile.path} (Size: $fileSizeMB MB)');

        var streamedResponse = await _httpClient.send(request).timeout(
            const Duration(seconds: 300),
            onTimeout: () {
          print('Request timed out after 300 seconds');
          throw TimeoutException('The 3D generation took too long.');
            },
        );

        var response = await http.Response.fromStream(streamedResponse);

        print('3D API Response Status: ${response.statusCode}');
        print('3D API Response Headers: ${response.headers}');
        if (response.statusCode != 200) {
          print('3D API Response Body: ${response.body}');
        }

        if (response.statusCode == 200) {
          var contentType = response.headers['content-type'];
          if (contentType?.contains('application/json') ?? false) {
            var jsonResponse = jsonDecode(response.body);
            var apiResponse = jsonResponse['apiResponse'];
            if (apiResponse != null && apiResponse.isNotEmpty) {
              var nestedJson = jsonDecode(apiResponse);
              String? modelUrl = nestedJson['output'];
              print('Extracted Model URL: $modelUrl');

              if (modelUrl != null && modelUrl.isNotEmpty) {
                if (modelUrl.toLowerCase().endsWith('.glb')||
                modelUrl.toLowerCase().endsWith('.gltf')) {
    bool isAccessible = await _isUrlAccessible(modelUrl);
    if (isAccessible) {
    setState(() {
    _modelUrl = modelUrl;
    _isLoading = false;
    });
    } else {
    setState(() {
    _errorMessage =
    '3D model is not accessible. Please try again later.';
    _isLoading = false;
    });
    }
    } else {
    setState(() {
    _errorMessage = 'Unsupported 3D model format.';
    _isLoading = false;
    });
    }
    } else {
    setState(() {
    _errorMessage = 'No valid 3D model URL provided by the server.';
    _isLoading = false;
    });
    }
    } else {
    setState(() {
    _errorMessage = 'Invalid response format from server.';
    _isLoading = false;
    });
    }
    } else {
    setState(() {
    _errorMessage = 'Unexpected response format: $contentType';
    _isLoading = false;
    });
    }
    } else if (response.statusCode == 429) {
    final retryAfter = response.headers['retry-after'];
    final waitTime = retryAfter != null ? int.tryParse(retryAfter) ?? 300 : 300;
    setState(() {
    _errorMessage =
    'Too many requests. Please wait ${waitTime ~/ 60} minute(s) and try again.';
    _isLoading = false;
    });
    } else {
    // Check if the error is due to server-side timeout
    if (response.body.contains('Timeout')) {
    if (retryCount < maxRetries) {
    retryCount++;
    print('Retrying request due to timeout (Attempt ${retryCount + 1})');
    await Future.delayed(Duration(seconds: 5 * retryCount)); // Exponential backoff
    continue; // Retry the request
    } else {
    setState(() {
    _errorMessage =
    '3D generation timed out on the server after multiple attempts. Please try again later.';
    _isLoading = false;
    });
    }
    } else {
    setState(() {
    _errorMessage =
    '3D generation failed: ${response.statusCode} - ${response.reasonPhrase}\n${response.body}';
    _isLoading = false;
    });
    }
    }
    break; // Exit the loop if the request succeeds or fails without retry
    } on TimeoutException {
    if (retryCount < maxRetries) {
    retryCount++;
    print('Retrying request due to timeout (Attempt ${retryCount + 1})');
    await Future.delayed(Duration(seconds: 5 * retryCount)); // Exponential backoff
    continue; // Retry the request
    } else {
      setState(() {
        _errorMessage =
        '3D generation timed out after 5 minutes despite multiple attempts. Please try again later.';
        _isLoading = false;
      });
    }
      } catch (e) {
        print('3D API Error: $e');
        setState(() {
          _errorMessage = 'Error during 3D generation: $e';
          _isLoading = false;
        });
        break;
      } finally {
        if (tempFile != null && await tempFile.exists()) {
          try {
            await tempFile.delete();
          } catch (e) {
            print('Failed to delete temporary file: $e');
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          '3D View',
          style: GoogleFonts.playfairDisplay(
            color: Color(0xFFC7836A),
            fontWeight: FontWeight.bold,
            fontSize: 26,
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
    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 39.0),
    child: Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
    Text(
    'Try-On Result :',
    style: TextStyle(
    fontSize: 19,
    fontWeight: FontWeight.w700,
    color: Color(0xFFC7836A),
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
    boxShadow: [
    BoxShadow(
    color: const Color(0x2CD29C7F),
    blurRadius: 6,
    offset: const Offset(0, 7),
    ),
    ],
    ),
    child: ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: Image.memory(
    widget.resultImageBytes,
    height: 320,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) {
    return Container(
    height: 320,
    color: Colors.grey[200],
    child: Center(
    child: Text(
    'Failed to display image',
    style: GoogleFonts.marmelad(
    color: Color(0xFFC7786A),
    fontSize: 16,
    ),
    textAlign: TextAlign.center,
    ),
    ),
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
            colors: [Color(0xFFDE9B88), Color(0xFFEECCB8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0x2CD29C7F),
              blurRadius: 6,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isLoading || !_canSendRequest() ? null : _generate3DModel,
          icon: _isLoading
              ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          )
              : const Icon(Icons.threed_rotation, size: 24, color: Colors.white),
          label: Text(
            _isLoading ? 'Generating...' : 'Generate 3D',
            style: GoogleFonts.marmelad(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 28),
            backgroundColor: Colors.transparent,

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
    child: Column(
    children: [
    Container(
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
    style: TextStyle(
    color: Color(0xFFD26147),
    fontSize: 14,
    fontWeight: FontWeight.w400,
    ),
    ),
    ),
    ],
    ),
    ),
    const SizedBox(height: 12),
    ElevatedButton(
    onPressed: _canSendRequest() ? _generate3DModel : null,
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFC7786A),
    ),
    child: Text(
    'Try Again',
    style:  TextStyle(
    color: Colors.white,
    ),
    ),
    ),
    ],
    ),
    ),
    if (_isLoading && _modelUrl == null)
    Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Center(
    child: Column(
    children: [
    const CircularProgressIndicator(
    color: Color(0xFFBE7D61),
    ),
    const SizedBox(height: 16),
    Text(
    'Generating 3D model... This may take a few minutes.',
    style: TextStyle(
    color: const Color(0xFFBE7D61),
    fontSize: 16,
    ),
    textAlign: TextAlign.center,
    ),
    ],
    ),
    ),
    ),
    if (_modelUrl != null)
    Column(
    children: [
    Text(
    'Your 3D Model',
    style: GoogleFonts.marmelad(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: const Color(0xFFBE7D61),
    ),
    ),
    const SizedBox(height: 16),
    Container(
    height: 400,
    decoration: BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
    color: const Color(0xFFF9E4E4),
    width: 2,
    ),
    ),
    child: FutureBuilder<bool>(
    future: _isUrlAccessible(_modelUrl!),
    builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
    child: CircularProgressIndicator(
    color: Color(0xFFBE7D61),
    ),
    );
    }
    if (snapshot.hasError || !snapshot.data!) {
    return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
    const Icon(Icons.error_outline, size: 48, color: Color(0xFFD26147)),
    const SizedBox(height: 16),
    Text(
    'Failed to load 3D model',
    style: TextStyle(
    color: Color(0xFFD26147),
    fontSize: 16,
    ),
    textAlign: TextAlign.center,
    ),
    const SizedBox(height: 16),
    ElevatedButton(
    onPressed: _canSendRequest() ? _generate3DModel : null,
    style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFFBE7D61),
    ),
    child: const Text('Try Again'),
    ),
    ],
    );
    }
    print('Loading ModelViewer with URL: $_modelUrl');
    return ModelViewer(
    src: _modelUrl!,
    alt: '3D Model',
    ar: false,
    autoRotate: true,
    cameraControls: true,
    backgroundColor: Colors.white,
    loading: Loading.eager,
    );
    },
    ),
    ),
    const SizedBox(height: 16),
    Text(
    'Use two fingers to rotate, pinch to zoom',
    style: GoogleFonts.marmelad(
    color: Color(0xFFBE7D61),
    fontStyle: FontStyle.italic,
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