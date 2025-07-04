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
        return macos;
      case TargetPlatform.windows:
        return windows;
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCikO3Wnn96PKt7bGxBSImwqT1udvYJTAQ',
    appId: '1:959832172654:android:5e378f6d9ad32edb58de7f',
    messagingSenderId: '959832172654',
    projectId: 'mettingapp-aef60',
    storageBucket: 'mettingapp-aef60.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyByBUngq93tfhcOKuZbyahDbLZbvly_iwk',
    appId: '1:959832172654:web:925745fd4655156d58de7f',
    messagingSenderId: '959832172654',
    projectId: 'mettingapp-aef60',
    authDomain: 'mettingapp-aef60.firebaseapp.com',
    storageBucket: 'mettingapp-aef60.firebasestorage.app',
    measurementId: 'G-VMPP7HB5F4',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC1TNW3-3bM2ipJUVpCI56hVUdHPJ5-z3U',
    appId: '1:959832172654:ios:fef0bef53648350258de7f',
    messagingSenderId: '959832172654',
    projectId: 'mettingapp-aef60',
    storageBucket: 'mettingapp-aef60.firebasestorage.app',
    iosBundleId: 'com.example.mobile',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC1TNW3-3bM2ipJUVpCI56hVUdHPJ5-z3U',
    appId: '1:959832172654:ios:fef0bef53648350258de7f',
    messagingSenderId: '959832172654',
    projectId: 'mettingapp-aef60',
    storageBucket: 'mettingapp-aef60.firebasestorage.app',
    iosBundleId: 'com.example.mobile',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyByBUngq93tfhcOKuZbyahDbLZbvly_iwk',
    appId: '1:959832172654:web:b03db838e8df7a2a58de7f',
    messagingSenderId: '959832172654',
    projectId: 'mettingapp-aef60',
    authDomain: 'mettingapp-aef60.firebaseapp.com',
    storageBucket: 'mettingapp-aef60.firebasestorage.app',
    measurementId: 'G-YZTC78Y8MP',
  );

}