import 'dart:io';
import 'package:image/image.dart';

void main() {
  final bytes = File('assets/icon/icon.png').readAsBytesSync();
  var img = decodeImage(bytes);
  if (img == null) return;

  int minX = img.width;
  int minY = img.height;
  int maxX = 0;
  int maxY = 0;

  // 1. Find the bounding box of the blue graduation cap (ignoring pale blue / white background)
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      final pixel = img.getPixel(x, y);
      final a = pixel.a;
      final r = pixel.r;
      final g = pixel.g;
      final b = pixel.b;
      
      // If it's quite blue (e.g. R is low, B is high) or dark enough
      // The pale blue background usually has high R, G, B (e.g., > 200). 
      // The white box is 255, 255, 255.
      // So if (r < 180 && b > 100 && a > 0), it's part of the cap.
      // We check for any color that is NOT mostly white/pale-blue:
      // So R < 200 AND G < 220 
      if (r < 200 && a > 0) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Cap bounded at: \$minX, \$minY, to \$maxX, \$maxY');

  // 2. Crop the exact cap
  final capImg = copyCrop(img, x: minX, y: minY, width: maxX - minX, height: maxY - minY);

  // 3. Make the background of the cap completely transparent just to be safe.
  for (final p in capImg) {
    if (p.r > 200) {
      p.a = 0;
    }
  }

  // 4. Create a new 512x512 transparent canvas
  final canvasSize = 1024;
  var finalImg = Image(width: canvasSize, height: canvasSize);
  // Optional: clear to transparent (already transparent by default in image package usually, but let's be sure)
  for (final p in finalImg) { p.a = 0; p.r = 0; p.g = 0; p.b = 0; }
  
  // 5. Scale the cap so it takes up about 50-60% of the canvas width (safe zone for adaptive icons)
  final targetWidth = (canvasSize * 0.55).toInt();
  final targetHeight = (capImg.height * (targetWidth / capImg.width)).toInt();
  
  final scaledCap = copyResize(capImg, width: targetWidth, height: targetHeight, interpolation: Interpolation.linear);

  // 6. Draw the cap onto the center of the transparent canvas
  final offsetX = (canvasSize - targetWidth) ~/ 2;
  final offsetY = (canvasSize - targetHeight) ~/ 2;
  
  compositeImage(finalImg, scaledCap, dstX: offsetX, dstY: offsetY);

  // 7. Save to disk
  File('assets/icon/icon_foreground_true.png').writeAsBytesSync(encodePng(finalImg));
  print('Successfully created transparent centered cap!');
}
