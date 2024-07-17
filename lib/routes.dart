import 'package:flutter/material.dart';
import 'src/screens/auth/Login.dart';
import 'src/screens/auth/Register.dart';
import 'src/screens/customer/Homepage.dart';
import 'src/screens/delivery/Dashboard.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String homepage = '/homepage';
  static const String dashboard = '/dashboard';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return MaterialPageRoute(builder: (_) => const Login());
      case register:
        return MaterialPageRoute(builder: (_) => const Register());
      case homepage:
        return MaterialPageRoute(builder: (_) => const Homepage());
      case dashboard:
        return MaterialPageRoute(builder: (_) => const Dashboard());
      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        body: Center(
          child: Text('No route defined for ${settings.name}'),
        ),
      ),
    );
  }
}
