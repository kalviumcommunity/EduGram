import 'dart:io';
import 'package:image/image.dart';

void main() {
  final bytes = File('assets/icon/icon.png').readAsBytesSync();
  final img = decodeImage(bytes);
  if (img == null) return;
  
  for (final pixel in img) {
    // The graduation cap is blue (red usually < 50).
    // The background is pale blue (red usually > 200).
    // Using > 150 is very safe to identify background pixels.
    if (pixel.r > 150) {
      pixel.a = 0; // Make background transparent
    }
  }

  File('assets/icon/icon_foreground.png').writeAsBytesSync(encodePng(img));
  print('Done converting!');
}
