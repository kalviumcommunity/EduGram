// File generated from google-services.json
// Project: edugram-c8413

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'add GoogleService-Info.plist to ios/Runner and re-run FlutterFire CLI.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAvj9pxZySX2xCc9odUOYH5sia8IBHJHlw',
    appId: '1:1005292853747:android:c96585009a4f5617ba1a86',
    messagingSenderId: '1005292853747',
    projectId: 'edugram-c8413',
    storageBucket: 'edugram-c8413.firebasestorage.app',
  );
}
