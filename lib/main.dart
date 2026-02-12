import 'package:flat_chore/screens/wrapper.dart';
import 'package:flat_chore/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
     await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FlatChore',
      theme: appTheme,
      home: const Wrapper(), // Wrapper will handle Auth state
      debugShowCheckedModeBanner: false,
    );
  }
}
