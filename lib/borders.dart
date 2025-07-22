import 'package:image/image.dart' as img;
import 'dart:math';


class ShapeMask {
  final img.Image image;

  ShapeMask(this.image);

  /// Creates a circular mask for the given image
  img.Image applyCircularMask() {
    int width = image.width;
    int height = image.height;
    img.Image maskedImage = img.Image(width, height);

    int centerX = width ~/ 2;
    int centerY = height ~/ 2;
    int radius = (width < height ? width : height) ~/ 2;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        int dx = centerX - x;
        int dy = centerY - y;
        double distance = sqrt(dx * dx + dy * dy);


        if (distance <= radius) {
          maskedImage.setPixel(x, y, image.getPixel(x, y));
        } else {
          maskedImage.setPixel(x, y, img.getColor(0, 0, 0, 0)); // Transparent pixel
        }
      }
    }

    return maskedImage;
  }

  /// Creates a rounded rectangle mask for the given image
  img.Image applyRoundedRectMask(int cornerRadius) {
    int width = image.width;
    int height = image.height;
    img.Image maskedImage = img.Image(width, height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        bool insideRect = (x >= cornerRadius && x < width - cornerRadius) || (y >= cornerRadius && y < height - cornerRadius);

        if (insideRect) {
          maskedImage.setPixel(x, y, image.getPixel(x, y));
        } else {
          int dx = (x < cornerRadius) ? cornerRadius - x : x - (width - cornerRadius);
          int dy = (y < cornerRadius) ? cornerRadius - y : y - (height - cornerRadius);
          if ((dx * dx + dy * dy) <= (cornerRadius * cornerRadius)) {
            maskedImage.setPixel(x, y, image.getPixel(x, y));
          } else {
            maskedImage.setPixel(x, y, img.getColor(0, 0, 0, 0)); // Transparent pixel
          }
        }
      }
    }

    return maskedImage;
  }
}
