import 'package:flutter/material.dart';

class DotsRectangle extends StatelessWidget {
  final int rows;
  final int columns;
  final double dotSize;
  final double spacing;

  DotsRectangle({
    this.rows = 5,
    this.columns = 10,
    this.dotSize = 5.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (rowIndex) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(columns, (colIndex) {
            return Container(
              margin: EdgeInsets.all(spacing / 2),
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      }),
    );
  }
}
