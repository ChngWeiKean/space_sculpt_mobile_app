import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class CustomerOrderStatus extends StatefulWidget {
  final String orderId;

  const CustomerOrderStatus({super.key, required this.orderId});

  @override
  _CustomerOrderStatusState createState() => _CustomerOrderStatusState();
}

class _CustomerOrderStatusState extends State<CustomerOrderStatus> {
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
      _fetchUserData(),
    ]);
  }

  Future<void> _fetchOrderData() async {
    final snapshot = await _dbRef.child('orders/${widget.orderId}').get();
    if (snapshot.exists) {
      _orderData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {});
      await _fetchDriverData();
    }
  }

  Future<void> _fetchDriverData() async {
    if (_orderData != null) {
      final snapshot = await _dbRef.child('drivers/${_orderData!['driver_id']}').get();
      if (snapshot.exists) {
        final driverData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _orderData!['driver_data'] = driverData;
        });
      }
    }
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser.uid}').get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _userData = userData;
        });
      }
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
      case 'On Hold':
        return 'Your order is currently on hold.';
      case 'Resolved':
        return 'Your issue has been resolved.';
      case 'Completed':
        return 'Your order is completed.';
      default:
        return 'Unknown status.';
    }
  }

  String _getCurrentStatus(Map<dynamic, dynamic> status) {
    status.keys.toList().sort((a, b) {
      final aDate = DateTime.parse(status[a]);
      final bDate = DateTime.parse(status[b]);
      return bDate.compareTo(aDate);
    });

    if (status['Completed'] != null) return 'Completed';
    if (status['Resolved'] != null) return 'Resolved';
    if (status['OnHold'] != null) return 'On Hold';
    if (status['Arrived'] != null) return 'Arrived';
    if (status['Shipping'] != null) return 'Shipping';
    if (status['ReadyForShipping'] != null) return 'Ready For Shipping';
    if (status['Pending'] != null) return 'Pending';
    return 'Unknown';
  }

  String _getDetailedStatusDescription(Map<dynamic, dynamic> status) {
    final String currentStatus = _getCurrentStatus(status);
    final DateFormat formatter = DateFormat('dd MMM');
    String date = '';

    if (status[currentStatus] != null) {
      final DateTime dateTime = DateTime.parse(status[currentStatus]);
      date = formatter.format(dateTime);
    } else if (currentStatus == 'Ready For Shipping') {
      final DateTime dateTime = DateTime.parse(status['ReadyForShipping']);
      date = formatter.format(dateTime);
    } else if (currentStatus == 'On Hold') {
      final DateTime dateTime = DateTime.parse(status['OnHold']);
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
      case 'On Hold':
        return '$date - Your order is currently on hold. Our team is working to resolve any issues that may have occurred during the delivery process.';
      case 'Resolved':
        return '$date - Your issue has been resolved. We apologize for any inconvenience caused and appreciate your patience.';
      case 'Completed':
        return '$date - Your order has been successfully completed and delivered. We appreciate your trust in our service and hope you are satisfied with your purchase.';
      default:
        return 'The current status of your order is unknown. Please check your order details or contact our support team for more information.';
    }
  }

  List<Widget> _buildTimeline() {
    final Map<String, String> baseStatuses = {
      'Pending': 'Order Placed',
      'ReadyForShipping': 'Ready For Shipping',
      'Shipping': 'Shipped',
      'Arrived': 'Delivered',
    };

    final DateFormat formatter = DateFormat('dd MMM yyyy hh:mm a');
    final Map<String, String> statuses = Map.from(baseStatuses);

    if (_orderData!['completion_status']['Resolved'] != null) {
      statuses['Resolved'] = 'Resolved';
    }

    if (_orderData!['completion_status']['OnHold'] != null) {
      statuses['OnHold'] = 'On Hold';
    } else {
      statuses['Completed'] = 'Completed';
    }

    return statuses.keys.map((statusKey) {
      String displayStatus = statuses[statusKey]!;
      String date = '';
      bool hasTimestamp = _orderData!['completion_status'][statusKey] != null;

      if (hasTimestamp) {
        final DateTime dateTime = DateTime.parse(_orderData!['completion_status'][statusKey]);
        date = formatter.format(dateTime);
      }

      final bool isOnHold = statusKey == 'OnHold';

      return TimelineTile(
        nodeAlign: TimelineNodeAlign.start,
        contents: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    displayStatus,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 13.0,
                      fontFamily: 'Poppins_Bold',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    date,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13.0,
                      fontFamily: 'Poppins_Bold',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              if (hasTimestamp)
                Text(
                  _getDetailedStatusDescription({statusKey: _orderData!['completion_status'][statusKey]}),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 11.0,
                    fontFamily: 'Poppins_Regular',
                  ),
                ),
              if (!hasTimestamp)
                const SizedBox(
                  height: 60.0, // Ensure the height remains consistent
                ),
            ],
          ),
        ),
        node: TimelineNode(
          indicator: DotIndicator(
            color: isOnHold
                ? Colors.red
                : hasTimestamp ? AppColors.secondary : Colors.grey,
            size: 16.0,
          ),
          startConnector: statuses.keys.first == statusKey
              ? null
              : hasTimestamp
              ? DecoratedLineConnector(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isOnHold
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.blue, Colors.lightBlueAccent[400]!],
              ),
            ),
          )
              : const SolidLineConnector(color: Colors.grey),
          endConnector: statuses.keys.last == statusKey
              ? null
              : hasTimestamp
              ? DecoratedLineConnector(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isOnHold
                    ? [Colors.red, Colors.redAccent]
                    : [Colors.blue, Colors.lightBlueAccent[400]!],
              ),
            ),
          )
              : const SolidLineConnector(color: Colors.grey),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _orderData == null && _userData == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          children: [
            const TitleBar(title: 'Delivery Details', hasBackButton: true),
            Container(
              height: 120,
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
                      _getStatusDescription(_getCurrentStatus(_orderData!['completion_status'])),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontFamily: 'Poppins_Bold',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Get by ${_orderData!['shipping_date']}',
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
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.only(left: 20.0, right: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _buildTimeline(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
