import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class CustomerOrderDetails extends StatefulWidget {
  final String orderId;

  const CustomerOrderDetails({required this.orderId, super.key});

  @override
  _CustomerOrderDetailsState createState() => _CustomerOrderDetailsState();
}

class _CustomerOrderDetailsState extends State<CustomerOrderDetails> {
  late DatabaseReference _dbRef;
  late User _currentUser;
  Map<dynamic, dynamic>? _orderData;
  Map<dynamic, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser!;
    _fetchData();
  }

  @override
  void dispose() {
    _dbRef.onDisconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    Future.wait([
      _fetchOrderData(),
    ]);
  }

  Future<void> _fetchOrderData() async {
    final snapshot = await _dbRef.child('orders/${widget.orderId}').get();
    if (snapshot.exists) {
      _orderData = snapshot.value as Map<dynamic, dynamic>;
      _fetchUserData();
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
      if (snapshot.exists) {
        _userData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {});
      }
    }
  }

  String _getCurrentStatus(Map<dynamic, dynamic> status) {
    if (status['Completed'] != null) return 'Completed';
    if (status['Resolved'] != null) return 'Resolved';
    if (status['OnHold'] != null) return 'Resolving Reports..';
    if (status['Arrived'] != null) return 'Arrived';
    if (status['Shipping'] != null) return 'Shipping';
    if (status['ReadyForShipping'] != null) return 'Ready For Shipping';
    if (status['Pending'] != null) return 'Pending';
    return 'Unknown';
  }

  String _getPaymentMethod(String method) {
    switch (method) {
      case 'cash':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'ewallet':
        return 'Touch \'n Go eWallet';
      default:
        return 'Unknown method';
    }
  }

  String _getStatusDescription(String status) {
    switch (status) {
      case 'Pending':
        return 'Your order is being processed.';
      case 'Ready For Shipping':
        return 'Your order is ready to be shipped.';
      case 'Shipping':
        return 'Your order is on the way.';
      case 'Arrived':
        return 'Your order has arrived at the destination.';
      case 'OnHold':
        return 'Your order is currently on hold.';
      case 'Resolved':
        return 'Your issue has been resolved.';
      case 'Completed':
        return 'Your order is completed.';
      default:
        return 'Unknown status.';
    }
  }

  String _getDetailedStatusDescription(Map<dynamic, dynamic> status) {
    final String currentStatus = _getCurrentStatus(status);
    final DateFormat formatter = DateFormat('dd MMM'); // Format for day and month
    String date = '';

    if (status[currentStatus] != null) {
      final DateTime dateTime = DateTime.parse(status[currentStatus]);
      date = formatter.format(dateTime);
    } else if (currentStatus == 'Ready For Shipping') {
      final DateTime dateTime = DateTime.parse(status['ReadyForShipping']);
      date = formatter.format(dateTime);
    }

    switch (currentStatus) {
      case 'Pending':
        return '$date - Your order is currently being processed by our system. We are working hard to ensure that your items are prepared and packaged with care.';
      case 'Ready For Shipping':
        return '$date - Great news! Your order has been packed and is ready for shipping. We are coordinating with our logistics partners to ensure a smooth and prompt delivery.';
      case 'Shipping':
        return '$date - Your order is on its way! Our delivery team is doing their best to bring your package to you as quickly as possible.';
      case 'Arrived':
        return '$date - Your order has arrived at the destination. Please be ready to receive your package.';
      case 'OnHold':
        return '$date - Your order is currently on hold. Our team is working to resolve any issues that may have occurred during the delivery process.';
      case 'Resolved':
        return '$date - Your issue has been resolved. We apologize for any inconvenience caused and appreciate your patience.';
      case 'Completed':
        return '$date - Your order has been successfully completed and delivered. We appreciate your trust in our service and hope you are satisfied with your purchase.';
      default:
        return 'The current status of your order is unknown. Please check your order details or contact our support team for more information.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _orderData == null && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const TitleBar(title: 'Order Details', hasBackButton: true),
            Container(
              height: 100,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getCurrentStatus(_orderData!['completion_status']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20.0,
                        fontFamily: 'Poppins_Bold',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _getStatusDescription(_getCurrentStatus(_orderData!['completion_status'])),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                        fontFamily: 'Poppins_Medium',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(
                          context,
                          Routes.customerOrderStatus, arguments: widget.orderId,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined, // Truck icon
                            color: Colors.black,
                            size: 18.0,
                          ),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              _getDetailedStatusDescription(_orderData!['completion_status']),
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 12.0,
                                fontFamily: 'Poppins_Regular',
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Icon(
                            Icons.arrow_forward_ios, // Accordion right icon
                            color: Colors.black,
                            size: 14.0,
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          '${_userData!['name']}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                              fontFamily: 'Poppins_Bold'
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_userData!['contact']}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12.0,
                              fontFamily: 'Poppins_Medium'
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_orderData!['address']['address']}',
                      style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12.0,
                          fontFamily: 'Poppins_Regular'
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: ListView.builder(
                padding: const EdgeInsets.all(0.0),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _orderData!['items'].length,
                itemBuilder: (context, index) {
                  final item = _orderData!['items'][index];
                  return Column(
                    children: [
                      ListTile(
                        leading: Image.network(
                          item['image'],
                          fit: BoxFit.contain,
                          width: 100,
                          height: 100,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                item['name'],
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Poppins_Bold',
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item['color']}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontFamily: 'Poppins_SemiBold',
                              ),
                            ),
                            item['discount'] != "0"
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RM ${(double.parse(item['price']) * (1 - double.parse(item['discount']) / 100)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins_Medium',
                                    fontSize: 13,
                                  ),
                                ),
                                Text('x ${item['quantity']}'),
                              ],
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'RM ${double.parse(item['price']).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontFamily: 'Poppins_Medium',
                                    fontSize: 13,
                                  ),
                                ),
                                Text('x ${item['quantity']}'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                        Text(
                          'RM ${_orderData!['subtotal']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shipping fee',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                        Text(
                          'RM ${_orderData!['shipping']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extra weight fee',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                        Text(
                          'RM ${_orderData!['weight']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Voucher',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                        Text(
                          '- RM ${_orderData!['discount']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Bold'),
                        ),
                        Text(
                          'RM ${_orderData!['total']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Bold'),
                        ),
                      ],
                    ),
                    Divider(
                      thickness: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text(
                          'Paid by',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Bold'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getPaymentMethod(_orderData!['payment']),
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                        Text(
                          'RM ${_orderData!['total']}',
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                    Divider(
                      thickness: 1,
                      height: 30,
                      color: Colors.grey[300],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Order No.',
                          style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Bold'),
                        ),
                        Text(
                          _orderData!['order_id'],
                          style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              color: Colors.white,

            )
          ],
        ),
      ),
    );
  }
}
