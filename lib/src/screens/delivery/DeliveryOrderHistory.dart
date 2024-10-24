import 'package:flutter/material.dart';
import '../../../colors.dart';
import '../../../routes.dart';
import '../../widgets/deliveryBottomNavBar.dart';
import '../../widgets/title.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DeliveryOrderHistory extends StatefulWidget {
  const DeliveryOrderHistory({super.key});

  @override
  _DeliveryOrderHistoryState createState() => _DeliveryOrderHistoryState();
}

class _DeliveryOrderHistoryState extends State<DeliveryOrderHistory> {
  final _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  List<Map<dynamic, dynamic>>? _orders;
  String _selectedSortOption = 'Order ID';

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

      // Sort orders by date
      validOrders.sort((b, a) => a['shipping_date'].compareTo(b['shipping_date']));

      setState(() {
        _orders = validOrders;
        _sortOrders();
      });
    }
  }

  void _sortOrders() {
    if (_orders == null) return;

    switch (_selectedSortOption) {
      case 'Order ID':
        _orders!.sort((a, b) => a['order_id'].compareTo(b['order_id']));
        break;
      case 'Status':
        _orders!.sort((a, b) => _getCurrentStatus(a['completion_status'])
            .compareTo(_getCurrentStatus(b['completion_status'])));
        break;
      case 'Contact':
        _orders!.sort((a, b) => a['user']['contact'].compareTo(b['user']['contact']));
        break;
      case 'Date':
        _orders!.sort((b, a) => a['shipping_date'].compareTo(b['shipping_date']));
        break;
      case 'Time':
        _orders!.sort((a, b) => a['shipping_time'].compareTo(b['shipping_time']));
        break;
    }
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

  void _navigateToOrderDetails(BuildContext context, String orderId) {
    Navigator.pushNamed(
      context,
      Routes.deliveryOrderDetails,
      arguments: orderId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(title: 'Order History'),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, bottom: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text('Sort by: ', style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium')),
                DropdownButton<String>(
                  value: _selectedSortOption,
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedSortOption = newValue!;
                      _sortOrders(); // Re-sort the orders whenever a new sort option is selected
                    });
                  },
                  items: <String>['Order ID', 'Status', 'Contact', 'Date', 'Time']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          Expanded(
            child: _orders == null
                ? const Center(child: CircularProgressIndicator())
                : _orders!.isEmpty
                ? const Center(child: Text('No orders found'))
                : SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 15,
                  dataRowMinHeight: 30,
                  dataRowMaxHeight: 80,
                  headingRowColor: WidgetStateColor.resolveWith(
                        (states) => Colors.grey[400]!,
                  ),
                  headingRowHeight: 40,
                  columns: const [
                    DataColumn(
                      label: Text('ID',
                          style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Bold')),
                    ),
                    DataColumn(
                      label: Text('Status',
                          style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Bold')),
                    ),
                    DataColumn(
                      label: Text('Contact',
                          style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Bold')),
                    ),
                    DataColumn(
                      label: Text('Date',
                          style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Bold')),
                    ),
                    DataColumn(label: Text('Time',
                        style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Bold')),
                    ),
                  ],
                  rows: _orders!.map((order) {
                    return DataRow(
                      cells: [
                        DataCell(
                          GestureDetector(
                            onTap: () => _navigateToOrderDetails(context, order['id'].toString()),
                            child: SizedBox(
                              width: 50,
                              child: Text(order['order_id'].toString(),
                                  overflow: TextOverflow.visible,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontFamily: 'Poppins_Medium',
                                      color: AppColors.secondary)),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100, // Set width for the 'Status' column
                            child: Text(_getCurrentStatus(order['completion_status']),
                                overflow: TextOverflow.visible,
                                style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100, // Set width for the 'Contact' column
                            child: Text(order['user']['contact'].toString(),
                                overflow: TextOverflow.visible,
                                style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 100, // Set width for the 'Date' column
                            child: Text(order['shipping_date'].toString(),
                                overflow: TextOverflow.visible,
                                style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 70, // Set width for the 'Time' column
                            child: Text(order['shipping_time'].toString(),
                                overflow: TextOverflow.visible,
                                style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const DeliveryBottomNavBar(initialIndex: 1),
    );
  }
}
