import 'package:appliedjobs/auth/authgate.dart';
import 'package:appliedjobs/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // 👈 Add this


@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message)async {
  await Firebase.initializeApp();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // ✅ Initialize Supabase
  await Supabase.initialize(
    url:
        'https://ephgcjpwnccrwcbzsotk.supabase.co', // 🔁 Replace with your Supabase project URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVwaGdjanB3bmNjcndjYnpzb3RrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDQ3OTg2NjksImV4cCI6MjA2MDM3NDY2OX0.MWDt2t_sVGQ-Y_hDiV-SiuRVyxR4_SROaJ9Omd_1egY', // 🔁 Replace with your Supabase anon/public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: AuthGate(),
    );
  }
}
