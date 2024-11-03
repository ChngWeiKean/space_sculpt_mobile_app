import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import '../../widgets/button.dart';
import '../../widgets/customerBottomNavBar.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class CustomerOrders extends StatefulWidget {
  const CustomerOrders({super.key});

  @override
  _CustomerOrdersState createState() => _CustomerOrdersState();
}

class _CustomerOrdersState extends State<CustomerOrders> {
  final _dbRef = FirebaseDatabase.instance.ref();
  User? _currentUser;
  Map<dynamic, dynamic>? _userData;
  List<Map<dynamic, dynamic>>? _orders;
  String _selectedFilter = 'All';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchData();
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
      _isLoading = true;
      final orderIds = _userData!['orders'] as List<dynamic>;

      final List<Map<dynamic, dynamic>> orders = [];

      for (final orderId in orderIds) {
        final snapshot = await _dbRef.child('orders/$orderId').get();
        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          data['id'] = snapshot.key;
          orders.add(data);
        }
      }

      // Sort orders by date
      orders.sort((a, b) {
        final aDate = DateTime.parse(a['created_on']);
        final bDate = DateTime.parse(b['created_on']);
        return bDate.compareTo(aDate);
      });

      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  List<Map<dynamic, dynamic>> _filterOrders() {
    if (_orders == null) return [];

    return _orders!.where((order) {
      final status = order['completion_status'] as Map<dynamic, dynamic>;
      // Sort the status by the latest status
      status.keys.toList().sort((a, b) {
        final aDate = DateTime.parse(status[a]);
        final bDate = DateTime.parse(status[b]);
        return bDate.compareTo(aDate);
      });
      final currentStatus = _getCurrentStatus(status);

      switch (_selectedFilter) {
        case 'All':
          return true;
        case 'To Ship':
          return currentStatus == 'Pending' || currentStatus == 'Ready For Shipping';
        case 'Reports':
          return currentStatus == 'On Hold';
        case 'To Receive':
          return currentStatus == 'Shipping' || currentStatus == 'Arrived' || currentStatus == 'Resolved';
        case 'Completed':
          return currentStatus == 'Completed';
        default:
          return false;
      }
    }).toList();
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

  void _navigateToOrderDetails(orderId) {
    Navigator.pushNamed(context, Routes.customerOrderDetails, arguments: orderId);
  }

  void _goShopping() {
    Navigator.pushNamed(context, Routes.homepage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orders == null
          ? Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Oops, Your Order History is Empty', style: TextStyle(fontSize: 16, fontFamily: 'Poppins_Bold')),
                const SizedBox(height: 10),
                const Text('Browse our awesome deals now!', style: TextStyle(fontSize: 12, fontFamily: 'Poppins_Medium')),
                const SizedBox(height: 20),
                Button(
                  onPressed: _goShopping,
                  text: 'Go Shopping Now',
                ),
              ],
            ),
          ),
        )
          : Stack(
        children: [
          Column(
            children: [
              const TitleBar(title: 'Orders'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterButton('All'),
                      _buildFilterButton('To Ship'),
                      _buildFilterButton('To Receive'),
                      _buildFilterButton('Reports'),
                      _buildFilterButton('Completed'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _filterOrders().length,
                  itemBuilder: (context, index) {
                    final order = _filterOrders()[index];
                    final items = order['items'] as List<dynamic>;

                    return GestureDetector(
                      onTap: () => _navigateToOrderDetails(order['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16.0),
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              spreadRadius: 2,
                              blurRadius: 5,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Order ID: ${order['order_id']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins_Semibold',
                                  ),
                                ),
                                Text(
                                  _getCurrentStatus(order['completion_status']),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontFamily: 'Poppins_Bold',
                                    color: AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8.0),
                            ListView.builder(
                              padding: const EdgeInsets.all(0.0),
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: items.length,
                              itemBuilder: (context, itemIndex) {
                                final item = items[itemIndex];
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
                                                'RM ${(double.parse(item['price']) * (1 - double.parse(item['discount'].toString()) / 100)).toStringAsFixed(2)}',
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
                            const SizedBox(height: 8.0),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total inclusive of charges: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins_Semibold',
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8.0),
                                Text(
                                  'RM ${order['total']}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontFamily: 'Poppins_Bold',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const CustomerBottomNavBar(initialIndex: 2),
    );
  }

  Widget _buildFilterButton(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        margin: const EdgeInsets.only(right: 8.0),
        decoration: BoxDecoration(
          color: _selectedFilter == title ? AppColors.secondary : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: _selectedFilter == title ? AppColors.secondary : Colors.grey,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: _selectedFilter == title ? Colors.white : AppColors.tertiary,
          ),
        ),
      ),
    );
  }
}
