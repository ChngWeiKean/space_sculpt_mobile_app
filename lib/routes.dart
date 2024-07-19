import 'package:flutter/material.dart';
import 'src/screens/auth/Login.dart';
import 'src/screens/auth/Register.dart';
import 'src/screens/auth/ForgotPassword.dart';
import 'src/screens/customer/Homepage.dart';
import 'src/screens/delivery/Dashboard.dart';
import 'src/screens/customer/CustomerProfile.dart';
import 'src/screens/customer/CustomerSettings.dart';
import 'src/screens/customer/CustomerEditProfile.dart';
import 'src/screens/auth/UpdateEmail.dart';
import 'src/screens/auth/UpdatePassword.dart';

class Routes {
  static const String login = '/login';
  static const String register = '/register';
  static const String updateEmail = '/update-email';
  static const String updatePassword = '/update-password';
  static const String homepage = '/homepage';
  static const String dashboard = '/dashboard';
  static const String forgotPassword = '/forgot-password';
  static const String customerProfile = '/customer-profile';
  static const String customerSettings = '/customer-settings';
  static const String customerEditProfile = '/customer-edit-profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case login:
        return _buildRoute(const Login());
      case register:
        return _buildRoute(const Register());
      case forgotPassword:
        return _buildRoute(const ForgotPassword());
      case homepage:
        return _buildRoute(const Homepage());
      case dashboard:
        return _buildRoute(const Dashboard());
      case customerProfile:
        return _buildRoute(const CustomerProfile());
      case customerSettings:
        return _buildRoute(const CustomerSettings());
      case customerEditProfile:
        return _buildRoute(const CustomerEditProfile());
      case updateEmail:
        return _buildRoute(const UpdateEmail());
      case updatePassword:
        return _buildRoute(const UpdatePassword());
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

  static PageRouteBuilder _buildRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.ease;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
    );
  }
}
