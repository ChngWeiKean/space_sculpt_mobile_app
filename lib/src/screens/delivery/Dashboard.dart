import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/deliveryBottomNavBar.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  List<Map<dynamic, dynamic>>? _orders;
  List<Map<dynamic, dynamic>>? _todayOrders;
  Map<String, int> _orderStatistics = {};

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchUserData(),
    ]);
  }

  Future<void> _fetchUserData() async {
    if (_currentUser != null) {
      final snapshot = await _dbRef.child('users/${_currentUser!.uid}').get();
      if (snapshot.exists) {
        final userData = snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          _userData = userData;
        });
      }

      await _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    if (_currentUser != null && _userData != null) {
      final orderIds = _userData!['pending_orders'] as List<dynamic>;

      final List<Future<Map<dynamic, dynamic>>> orderFutures = orderIds.map((orderId) async {
        final snapshot = await _dbRef.child('orders/$orderId').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          final userSnapshot = await _dbRef.child('users/${data['user_id']}').get();
          if (userSnapshot.exists) {
            data['user'] = userSnapshot.value;
          }
          data['id'] = snapshot.key;
          return data;
        } else {
          return {}; // Return an empty map if snapshot does not exist
        }
      }).toList();

      final orders = await Future.wait(orderFutures);

      // Filter out any empty maps (orders that did not exist)
      final validOrders = orders.where((order) => order.isNotEmpty).toList();

      // Sort orders by date, get today's orders, date format is 'yyyy-MM-dd'
      final todayOrders = validOrders.where((order) {
        final orderDate = DateTime.parse(order['shipping_date'] as String);
        final today = DateTime.now();
        return orderDate.year == today.year && orderDate.month == today.month && orderDate.day == today.day;
      }).toList();

      setState(() {
        _orders = validOrders;
        _todayOrders = todayOrders;
        _orderStatistics = _calculateOrderStatistics(validOrders);
      });
    }
  }

  Map<String, int> _calculateOrderStatistics(List<Map<dynamic, dynamic>> orders) {
    Map<String, int> statusCounts = {
      'Pending': 0,
      'Ready For Shipping': 0,
      'Shipping': 0,
      'Arrived': 0,
      'On Hold': 0,
      'Resolved': 0,
      'Completed': 0,
    };

    for (var order in orders) {
      String currentStatus = _getCurrentStatus(order['completion_status']);
      if (statusCounts.containsKey(currentStatus)) {
        statusCounts[currentStatus] = statusCounts[currentStatus]! + 1;
      }
    }

    return statusCounts;
  }

  String _getCurrentStatus(Map<dynamic, dynamic> status) {
    if (status['Completed'] != null) return 'Completed';
    if (status['Resolved'] != null) return 'Resolved';
    if (status['OnHold'] != null) return 'On Hold';
    if (status['Arrived'] != null) return 'Arrived';
    if (status['Shipping'] != null) return 'Shipping';
    if (status['ReadyForShipping'] != null) return 'Ready For Shipping';
    if (status['Pending'] != null) return 'Pending';
    return 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 16.0, right: 16.0,bottom: 10.0, top: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Image.asset('lib/src/assets/Space_Sculpt_Logo_nobg.png', height: 40),
                            const SizedBox(width: 10),
                            Text(
                              'Welcome, ${_userData!['name']}',
                              style: const TextStyle(
                                fontSize: 20.0,
                                fontFamily: 'Poppins_SemiBold',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ExpansionTile(
                        title: const Text(
                          'Your Statistics',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontFamily: 'Poppins_Bold',
                          ),
                        ),
                        backgroundColor: Colors.white,
                        collapsedBackgroundColor: Colors.white,
                        childrenPadding: EdgeInsets.zero,
                        tilePadding: const EdgeInsets.symmetric(horizontal: 15.0),
                        expandedCrossAxisAlignment: CrossAxisAlignment.start,
                        expandedAlignment: Alignment.centerLeft,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(15.0),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _orderStatistics.entries.map((entry) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Text(
                                    '${entry.key}: ${entry.value}',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontFamily: 'Poppins_Regular',
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              'Today\'s Orders',
                              style: TextStyle(
                                fontSize: 16.0,
                                fontFamily: 'Poppins_Bold',
                              ),
                            ),
                            const SizedBox(height: 10),
                            _todayOrders == null || _todayOrders!.isEmpty
                                ? Container(
                              alignment: Alignment.center,
                              width: double.infinity,
                              padding: const EdgeInsets.all(15.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: const Text(
                                'No orders for today',
                                style: TextStyle(
                                  fontSize: 15.0,
                                  fontFamily: 'Poppins_Semibold',
                                ),
                              ),
                            )
                                : Column(
                              children: _todayOrders!.map((order) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10.0),
                                  padding: const EdgeInsets.all(15.0),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10.0),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.receipt_long_outlined, color: AppColors.secondary, size: 25),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              'Order #${order['order_id']}',
                                              style: const TextStyle(
                                                fontSize: 15.0,
                                                fontFamily: 'Poppins_Semibold',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '${order['user']['name']}',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Poppins_Regular',
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        'Deliver by: ${order['shipping_date']}',
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                          fontFamily: 'Poppins_Regular',
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const DeliveryBottomNavBar(initialIndex: 0),
    );
  }
}
