import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'src/services/auth_wrapper.dart';
import 'routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase App',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF4F4F4),
        primarySwatch: Colors.blue,
        fontFamily: 'Poppins',
      ),
      home: const AuthenticationWrapper(),
      initialRoute: Routes.login,
      onGenerateRoute: Routes.generateRoute,
    );
  }
}
