import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timelines/timelines.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class DeliveryOrderStatus extends StatefulWidget {
  final String orderId;

  const DeliveryOrderStatus({super.key, required this.orderId});

  @override
  _DeliveryOrderStatusState createState() => _DeliveryOrderStatusState();
}

class _DeliveryOrderStatusState extends State<DeliveryOrderStatus> {
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
        return 'The order is being processed.';
      case 'Ready For Shipping':
        return 'The order is ready to be shipped.';
      case 'Shipping':
        return 'The order is on the way.';
      case 'Arrived':
        return 'The order has arrived at the destination.';
      case 'Completed':
        return 'The order is completed.';
      default:
        return 'Unknown status.';
    }
  }

  String _getCurrentStatus(Map<dynamic, dynamic> status) {
    if (status['Completed'] != null) return 'Completed';
    if (status['Arrived'] != null) return 'Arrived';
    if (status['Shipping'] != null) return 'Shipping';
    if (status['ReadyForShipping'] != null) return 'Ready For Shipping';
    if (status['Pending'] != null) return 'Pending';
    return 'Unknown';
  }

  String _getDetailedStatusDescription(Map<dynamic, dynamic> status) {
    final String currentStatus = _getCurrentStatus(status);
    final DateFormat formatter = DateFormat('dd MMM'); // Format for day and month
    String date = '';

    if (status[currentStatus] != null) {
      final DateTime dateTime = DateTime.parse(status[currentStatus]);
      date = formatter.format(dateTime);
    } else if (currentStatus == 'Ready For Shipping') {
      date = formatter.format(DateTime.parse(_orderData!['shipping_date']));
    }

    switch (currentStatus) {
      case 'Pending':
        return '$date - The order is being processed. Please be ready to pick it up for delivery soon.';
      case 'Ready For Shipping':
        return '$date - The order is ready for pickup. Coordinate with the logistics team to start the delivery.';
      case 'Shipping':
        return '$date - You are currently delivering this order. Please ensure it reaches the customer safely and on time.';
      case 'Arrived':
        return '$date - You have arrived at the destination. Please deliver the package to the customer and confirm the handover.';
      case 'Completed':
        return '$date - The delivery has been completed successfully. Thank you for ensuring the customer received their order.';
      default:
        return 'The current status of this order is unknown. Please check the order details or contact support for more information.';
    }
  }

  List<Widget> _buildTimeline() {
    final Map<String, String> statuses = {
      'Pending': 'Pending',
      'ReadyForShipping': 'Ready For Shipping',
      'Shipping': 'Shipping',
      'Arrived': 'Arrived',
      'Completed': 'Completed'
    };

    final DateFormat formatter = DateFormat('dd MMM yyyy hh:mm a');

    return statuses.keys.map((statusKey) {
      String displayStatus = statuses[statusKey]!;  // The friendly name
      String date = '';
      bool hasTimestamp = _orderData!['completion_status'][statusKey] != null;

      if (hasTimestamp) {
        final DateTime dateTime = DateTime.parse(_orderData!['completion_status'][statusKey]);
        date = formatter.format(dateTime);
      }

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
                  ]
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
            color: hasTimestamp ? AppColors.secondary : Colors.grey,
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
                colors: [Colors.blue, Colors.lightBlueAccent[400]!],
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
                colors: [Colors.blue, Colors.lightBlueAccent[400]!],
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
                      _getStatusDescription(_getCurrentStatus(_orderData!['completion_status'])),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontFamily: 'Poppins_Bold',
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Deliver by ${_orderData!['shipping_date']}',
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
