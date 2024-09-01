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
import 'src/screens/customer/CustomerFurnitureDetails.dart';
import 'src/screens/customer/CustomerCategoryDetails.dart';
import 'src/screens/customer/CustomerCart.dart';
import 'src/screens/customer/CustomerAddresses.dart';
import 'src/screens/customer/CustomerAddressDetails.dart';
import 'src/screens/customer/CustomerAddNewAddress.dart';
import 'src/screens/customer/CustomerVouchers.dart';
import 'src/screens/customer/CustomerCheckout.dart';
import 'src/screens/customer/CustomerPayment.dart';
import 'src/screens/customer/CustomerOrders.dart';
import 'src/screens/customer/CustomerOrderDetails.dart';
import 'src/screens/customer/CustomerOrderStatus.dart';
import 'src/screens/delivery/DeliveryOrderHistory.dart';
import 'src/screens/delivery/DeliveryOrderDetails.dart';
import 'src/screens/delivery/DeliveryOrderStatus.dart';
import 'src/screens/delivery/DeliveryDriverProfile.dart';
import 'src/screens/delivery/DeliveryDriverEditProfile.dart';
import 'src/screens/delivery/DeliveryDriverSettings.dart';

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
  static const String customerFurnitureDetails = '/customer-furniture-details';
  static const String customerCategoryDetails = '/customer-category-details';
  static const String customerCart = '/customer-cart';
  static const String customerAddresses = '/customer-addresses';
  static const String customerAddressDetails = '/customer-address-details';
  static const String customerAddNewAddress = '/customer-add-new-address';
  static const String customerVouchers = '/customer-vouchers';
  static const String customerCheckout = '/customer-checkout';
  static const String customerPayment = '/customer-payment';
  static const String customerOrders = '/customer-orders';
  static const String customerOrderDetails = '/customer-order-details';
  static const String customerOrderStatus = '/customer-order-status';
  static const String deliveryOrderHistory = '/delivery-order-history';
  static const String deliveryOrderDetails = '/delivery-order-details';
  static const String deliveryOrderStatus = '/delivery-order-status';
  static const String deliveryDriverProfile = '/delivery-driver-profile';
  static const String deliveryDriverEditProfile = '/delivery-driver-edit-profile';
  static const String deliveryDriverSettings = '/delivery-driver-settings';

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
      case customerFurnitureDetails:
        return _buildRoute(CustomerFurnitureDetails(id: settings.arguments as String));
      case customerCategoryDetails:
        return _buildRoute(CustomerCategoryDetails(id: settings.arguments as String));
      case customerCart:
        return _buildRoute(const CustomerCart());
      case customerAddresses:
        return _buildRoute(const CustomerAddresses());
      case customerAddressDetails:
        return _buildRoute(CustomerAddressDetails(address: settings.arguments as Map<dynamic, dynamic>));
      case customerAddNewAddress:
        return _buildRoute(const CustomerAddNewAddress());
      case customerVouchers:
        return _buildRoute(const CustomerVouchers());
      case customerCheckout:
        return _buildRoute(CustomerCheckout(cartItems: settings.arguments as List<Map<dynamic, dynamic>>));
      case customerPayment:
        return _buildRoute(CustomerPayment(checkoutData: settings.arguments as Map<String, dynamic>));
      case customerOrders:
        return _buildRoute(const CustomerOrders());
      case customerOrderDetails:
        return _buildRoute(CustomerOrderDetails(orderId: settings.arguments as String));
      case customerOrderStatus:
        return _buildRoute(CustomerOrderStatus(orderId: settings.arguments as String));
      case deliveryOrderHistory:
        return _buildRoute(const DeliveryOrderHistory());
      case deliveryOrderDetails:
        return _buildRoute(DeliveryOrderDetails(orderId: settings.arguments as String));
      case deliveryOrderStatus:
        return _buildRoute(DeliveryOrderStatus(orderId: settings.arguments as String));
      case deliveryDriverProfile:
        return _buildRoute(const DeliveryDriverProfile());
      case deliveryDriverEditProfile:
        return _buildRoute(const DeliveryDriverEditProfile());
      case deliveryDriverSettings:
        return _buildRoute(const DeliveryDriverSettings());
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

  static MaterialPageRoute _buildRoute(Widget page) {
    return MaterialPageRoute(
      builder: (context) => page,
    );
  }
}
