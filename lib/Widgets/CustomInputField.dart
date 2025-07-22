import 'package:flutter/material.dart';

class CustomInputField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final double widthFactor; // New parameter for custom width
  final double heightFactor; // New parameter for custom height

  const CustomInputField({
    Key? key,
    required this.hintText,
    required this.widthFactor,
    required this.heightFactor,
    required this.icon,
    this.obscureText = false,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    // Calculate the width and height based on factors
    double width = size.width * widthFactor;
    double height = size.height * heightFactor;

    return Container(
      width: width, // Customizable width
      height: height, // Customizable height
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Stack(
              children: [
                // Ensure the stack has a defined height
                SizedBox(
                  width: width, // Use width factor for dynamic sizing
                  height: height, // Set height based on heightFactor
                  child: Image.asset(
                    "assets/images/InputBorder4_enhanced.png",
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  top: 8.88,
                  left: 18,
                  child: Row(
                    children: [
                      Icon(icon, color: Color(0xFFAF7B66)),
                      SizedBox(width: 10),
                      Container(
                        width: width - 28, // Adjust width dynamically (remove margin)
                        child: TextField(
                          controller: controller ?? TextEditingController(),
                          obscureText: obscureText,
                          decoration: InputDecoration(
                            hintText: hintText,
                            hintStyle: TextStyle(color: Color(0xFFAF7B66)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
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
