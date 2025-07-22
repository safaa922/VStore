import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_store/constants.dart';
import 'package:virtual_store/screens/CRUD_PROD/ProdPhotos.dart';

class CreateProd extends StatefulWidget {

  final String userId;

  CreateProd({required this.userId});

  @override
  _CreateProdState createState() => _CreateProdState();
}

enum Category {
  Men,
  Women,
  Kids,
}


class _CreateProdState extends State<CreateProd> {
  Category? selectedCategory;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController materialController = TextEditingController();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController offerController = TextEditingController();
  final TextEditingController DescriptionController = TextEditingController();


  List<dynamic> categories = [];
  bool hasSale = false; // Track the state of the "Has Sale" switch

  @override
  void initState() {
    super.initState();

  }


  Future<void> saveAuthToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token); // Save the token in SharedPreferences
  }

  Future<String?> getAuthToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token'); // Retrieve the token from SharedPreferences
  }


  int? selectedCategoryId;
  Map<int, String> categoryMap = {}; // Stores categoryId -> categoryName




  void printAuthToken() async {
    String? token = await getAuthToken();
    print('Auth Token: $token');
  }


  bool isTokenExpired(String token) {
    final parts = token.split('.');
    if (parts.length == 3) {
      final payload = base64Url.decode(base64Url.normalize(parts[1]));
      final payloadMap = json.decode(utf8.decode(payload));
      final exp = payloadMap['exp'];
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      return expirationTime.isBefore(DateTime.now());
    }
    return true;
  }


  void createProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    _formKey.currentState!.save();

    String? token = await getAuthToken();
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    // Create a map with all the necessary data, including the description
    Map<String, dynamic> productData = {
      'ProductName': nameController.text,
      'Material': materialController.text,
      'Product_Type': typeController.text,
      'Product_Price': double.parse(priceController.text),
      'SalePercentage': hasSale ? int.parse(offerController.text) : 0,
      'Category': selectedCategory?.toString().split('.').last, // Send the category name
      'Has_Sale': hasSale,
      'Product_Description': DescriptionController.text, // Add the description here
    };

    // Navigate to the ProdPhotos screen and pass the product data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProdPhotos(productData: productData,userId: widget.userId),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double imageSize = screenHeight * 0.36;

    return Scaffold(
      backgroundColor: Color(0xFFFCF8F6),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                'assets/images/BohoMainTwo3.png',
                fit: BoxFit.fitWidth,
                width: double.infinity,
                height: imageSize,
              ),

              Positioned(
                top: 50,
                left: 13,
                child: IconButton(
                  icon: Icon(CupertinoIcons.left_chevron, color: Color(
                      0xFFD7967B), size: 25),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          Expanded(
            child: Container(
              height: screenHeight * 0.68,
              padding: const EdgeInsets.all(30.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Container(
                            width: screenWidth * 0.4,
                            child: buildTextField(
                              controller: nameController,
                              label: 'Title',
                              icon: Icons.title,
                              validator: (value) => value!.isEmpty ? 'Please enter a title' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: buildDropdownField(
                              label: 'Category',
                              icon: Icons.category_outlined,
                              value: selectedCategory?.toString().split('.').last,
                              items: Category.values
                                  .map<DropdownMenuItem<String>>(
                                    (category) => DropdownMenuItem<String>(
                                  value: category.toString().split('.').last,
                                  child: Text(
                                    category.toString().split('.').last,
                                    style: TextStyle(fontSize: 12.3, color: Color(
                                        0xFFBB8D7B),height: 3.3),
                                  ),
                                ),
                              )
                                  .toList(),
                              onChanged: (value) => setState(() {
                                selectedCategory = Category.values.firstWhere(
                                      (category) => category.toString().split('.').last == value,
                                );
                              }),
                              validator: (value) => value == null ? 'Please select a category' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: materialController,
                              label: 'Material',
                              icon: Icons.design_services,
                              validator: (value) => value!.isEmpty ? 'Please enter material' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: buildTextField(
                              controller: typeController,
                              label: 'Type',
                              icon: Icons.checkroom,

                              validator: (value) => value!.isEmpty ? 'Please enter Type' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 23),
                      Row(
                        children: [
                          Expanded(
                            child: buildTextField(
                              controller: priceController,
                              label: 'Price',
                              icon: Icons.attach_money,
                              maxLength: 16,
                              keyboardType: TextInputType.number,
                              validator: (value) => value!.isEmpty ? 'Please enter price' : null,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: buildTextField(
                              controller: DescriptionController, // Use DescriptionController here
                              label: 'Description',
                              icon: Icons.description,
                              validator: (value) => value!.isEmpty ? 'Please enter description' : null,
                            ),
                          ),

                        ],
                      ),
                      const SizedBox(height: 23),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              'Has Offer',
                              style: TextStyle(fontSize: 15, color: Color(
                                  0xFFC5856B)),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Container(
                            height: 33,
                            width: 53,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(40),
                              border: Border.all(
                                color: hasSale ? Color(0xFFDFAD98) : Color(0xFFDFAD98),
                                width: 2.0,
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(3),
                              child: Switch(
                                value: hasSale,
                                onChanged: (value) {
                                  setState(() {
                                    hasSale = value;
                                  });
                                },
                                activeColor: Color(0xFFE3A388),
                                inactiveTrackColor: Colors.transparent,
                                inactiveThumbColor: Color(0xFFE3A388),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                trackOutlineColor: MaterialStateProperty.all(Colors.transparent),
                              ),
                            ),
                          ),
                          if (hasSale)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 25.0),
                                child: buildTextField(
                                  controller: offerController,
                                  label: 'Offer',
                                  icon: Icons.local_offer_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value!.isEmpty ? 'Please enter offer' : null,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: screenWidth * 0.73,
                        child: ElevatedButton(
                          onPressed: createProduct,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFE5A885),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 24, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,

    bool isFilled = false,
    Color fillColor = Colors.transparent,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: 149,
      height: 63,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/InputBorder4_enhanced.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                maxLength: maxLength,
                validator: validator,
                style: TextStyle(color: Color(0xFFC5856B),fontSize: 14.7), // Makes user input text red
                decoration: InputDecoration(
                  hintText: label,
                  hintStyle: TextStyle(
                    color: Color(0xFFC5856B),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(icon, size: 18, color: Color(0xFFC5856B)),
                  border: InputBorder.none,
                  filled: isFilled,
                  fillColor: fillColor,
                  counterText: '',
                  contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 9),
                  errorStyle: TextStyle(
                    fontSize: 12,
                    height: 0.60, // Reduce height to prevent shifts
                  ),
                ),
              ),

            ),
          ),
        ],
      ),
    );
  }


  Widget buildDropdownField({
    required String label,
    required IconData icon,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
    String? Function(String?)? validator,
  }) {
    return Container(
      width: 100,
      height: 63,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/InputBorder4_enhanced.png'),
          fit: BoxFit.fill,
        ),
      ),
      child: Stack(
        children: [
          AnimatedPositioned(
            top: value != null && value.isNotEmpty ? 40.9 : 0,
            left: 10,
            duration: Duration(milliseconds: 200),
            child: AnimatedOpacity(
              opacity: value != null && value.isNotEmpty ? 1.0 : 0.0,
              duration: Duration(milliseconds: 200),
              child: Text(

                label,
                style: TextStyle(
                  fontSize: 12,
                  height: 2.19,
                  color: Color(0xFFC28F7A),
                ),

              ),
            ),
          ),
      DropdownButtonFormField<String>(
        value: value,
        onChanged: onChanged,
        validator: validator,
        items: items,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, size: 18, color: Color(0xFFC28F7A)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10), // Adjust vertical padding
          hintText: 'Category',
          hintStyle: TextStyle(
            color: Color(0xFFC28F7A),
            fontSize: 13.3,
            height: 2.5, // Adjust this to move hint text slightly
          ),
        ),
        isDense: true,
        icon: SizedBox.shrink(),
        dropdownColor: Colors.white,
        menuMaxHeight: 250,



          ),
        ],
      ),
    );
  }
}
