import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.android:
        return android;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBh25Ko40qbhqo5a4NPWhLFDRkGq7EEWdw',
    appId: '1:127205810460:web:d45d55dbcf9a8aa6579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    authDomain: 'login-aydigi.firebaseapp.com',
    storageBucket: 'login-aydigi.firebasestorage.app',
    measurementId: 'G-C157ZYP8ZS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAE0dLy25Mm6ie2ZldeKGvflGxOsfEKoI4',
    appId: '1:127205810460:android:04b6ca76909235d6579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    storageBucket: 'login-aydigi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB1Jxdsd71X1WNKuLH9Ak9fv8OJrNdLaGY',
    appId: '1:127205810460:ios:24d3249ab52b5a6e579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    storageBucket: 'login-aydigi.firebasestorage.app',
    iosBundleId: 'com.example.login',
    iosClientId: '127205810460-i1g216e160mtqdsqo1n7sc7g14h193ie.apps.googleusercontent.com',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyB1Jxdsd71X1WNKuLH9Ak9fv8OJrNdLaGY',
    appId: '1:127205810460:ios:24d3249ab52b5a6e579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    storageBucket: 'login-aydigi.firebasestorage.app',
    iosBundleId: 'com.example.login',
    iosClientId: '127205810460-i1g216e160mtqdsqo1n7sc7g14h193ie.apps.googleusercontent.com',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBh25Ko40qbhqo5a4NPWhLFDRkGq7EEWdw',
    appId: '1:127205810460:web:d45d55dbcf9a8aa6579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    authDomain: 'login-aydigi.firebaseapp.com',
    storageBucket: 'login-aydigi.firebasestorage.app',
    measurementId: 'G-C157ZYP8ZS',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyBh25Ko40qbhqo5a4NPWhLFDRkGq7EEWdw',
    appId: '1:127205810460:web:d45d55dbcf9a8aa6579ad9',
    messagingSenderId: '127205810460',
    projectId: 'login-aydigi',
    authDomain: 'login-aydigi.firebaseapp.com',
    storageBucket: 'login-aydigi.firebasestorage.app',
    measurementId: 'G-C157ZYP8ZS',
  );
}
