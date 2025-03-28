// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCpWP8hPik1ROg3rfVRB638pRZL7VyTBQI',
    appId: '1:534005978803:web:0cfbf1413bff21feaa02c6',
    messagingSenderId: '534005978803',
    projectId: 'appliedjobs-92085',
    authDomain: 'appliedjobs-92085.firebaseapp.com',
    storageBucket: 'appliedjobs-92085.firebasestorage.app',
    measurementId: 'G-LCQT7BK2Q0',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyD27l40KmAvd69hhOlerY93Hg7D720ZLFY',
    appId: '1:534005978803:android:1f45411ae6313dacaa02c6',
    messagingSenderId: '534005978803',
    projectId: 'appliedjobs-92085',
    storageBucket: 'appliedjobs-92085.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBRiqgvxwkBPb0YvP3sMDVsxK9BjSDsJ78',
    appId: '1:534005978803:ios:ec95c880221bf1c4aa02c6',
    messagingSenderId: '534005978803',
    projectId: 'appliedjobs-92085',
    storageBucket: 'appliedjobs-92085.firebasestorage.app',
    iosBundleId: 'com.example.appliedjobs',
  );
}
