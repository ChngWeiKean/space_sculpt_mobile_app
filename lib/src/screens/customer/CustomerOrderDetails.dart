import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:space_sculpt_mobile_app/src/services/checkout_service.dart';
import 'package:space_sculpt_mobile_app/src/services/delivery_service.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/title.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import '../../../colors.dart';
import '../../../routes.dart';

class CustomerOrderDetails extends StatefulWidget {
  final String orderId;

  const CustomerOrderDetails({required this.orderId, super.key});

  @override
  _CustomerOrderDetailsState createState() => _CustomerOrderDetailsState();
}

class _CustomerOrderDetailsState extends State<CustomerOrderDetails> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
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
    _descriptionController.dispose();
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
      _remarksController.text = _orderData!['remarks'] ?? '';
      _orderData!['items'] = _orderData!['items'].map((item) {
        return {
          ...item,
          'isChecked': false,
        };
      }).toList();

      if (_orderData!['reports'] != null) {
        final reports = _orderData!['reports'] as String;
        final reportSnapshot = await _dbRef.child('reports/$reports').get();
        if (reportSnapshot.exists) {
          final reportData = reportSnapshot.value as Map<dynamic, dynamic>;
          _orderData!['report'] = reportData;
        }
      }
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

  Future<void> _completeOrder() async {
    // Check if all items are checked
    if (_orderData!['items'].every((item) => item['isChecked'] == true)) {
      await DeliveryService().updateStatus(widget.orderId, 'Completed');

      if (!context.mounted) return;

      Toast.showSuccessToast(
        title: "Order completed",
        description: "Your order has been successfully completed",
        context: context,
      );
    } else {
      Toast.showErrorToast(
          title: "Error completing order",
          description: "Please check all items before completing order",
          context: context);
    }
  }

  void _openReportDeliveryModal(BuildContext context, dynamic items) {
    // Safely convert items to List<Map<String, dynamic>>
    final List<Map<String, dynamic>> orderItems = (items as List<dynamic>).map((item) {
      return Map<String, dynamic>.from(item as Map); // Ensure each item is a Map<String, dynamic>
    }).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Report Incomplete Delivery / Damaged Products',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const Divider(thickness: 1, color: Colors.black26),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: orderItems.length,
                      itemBuilder: (context, index) {
                        final item = orderItems[index];
                        final isChecked = item['isChecked'] ?? false;

                        // Calculate the final price considering any discounts
                        final price = double.tryParse(item['price']) ?? 0.0;
                        final discount = double.tryParse(item['discount']) ?? 0.0;
                        final finalPrice = price * (1 - discount / 100);

                        return isChecked
                            ? Container()
                            : Column(
                          children: [
                            ListTile(
                              title: Row(
                                children: [
                                  Text(
                                    item['name'] ?? '',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Row(
                                children: [
                                  Text(
                                    item['color'] ?? '',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'RM ${finalPrice.toStringAsFixed(2)} x ${item['quantity']}',
                                    style: const TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 11,
                                    ),
                                  ),
                                ]
                              ),
                              trailing: DropdownButton<String>(
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                ),
                                hint: const Text('Select a report type'),
                                value: item['reportType'],
                                items: const [
                                  DropdownMenuItem(
                                    value: 'damaged',
                                    child: Text('Damaged Product'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'missing',
                                    child: Text('Missing Product'),
                                  ),
                                ],
                                onChanged: (value) {
                                  print('Selected report type: $value');
                                  setState(() {
                                    orderItems[index]['reportType'] = value;
                                  });
                                },
                              ),
                            ),
                            const Divider(),
                          ],
                        );
                      },
                    ),
                  ),
                  if (orderItems.every((item) => item['isChecked'] == true))
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'All items are checked. Please uncheck the items that are damaged or not delivered.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  if (orderItems.any((item) => item['isChecked'] == false))
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Report Description',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.all(8),
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Report description cannot be empty';
                          }
                          return null;
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        if (orderItems.any((item) => item['isChecked'] == false))
                          Button(
                              text: "Report",
                              width: 150,
                              onPressed: () {
                                handleReportDelivery(orderItems);
                              }
                          ),
                        const SizedBox(width: 8),
                        Button(
                          text: "Cancel",
                          color: AppColors.error,
                          width: 150,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> handleReportDelivery(List<Map<String, dynamic>> orderItems) async {
    final String reportDescription = _descriptionController.text;

    if (reportDescription.isEmpty) {
      // Show error toast before async operation
      Toast.showErrorToast(
        title: 'Error reporting delivery',
        description: 'Please provide a description for the report',
        context: context,
      );
      return;
    }

    final List<Map<String, dynamic>> reportedItems = orderItems.where((item) {
      final reportType = item['reportType'];
      return reportType != null && reportType.isNotEmpty && !item['isChecked'];
    }).toList();

    // Check if every non-checked item has a reportType
    final hasMissingReportType = orderItems.any((item) {
      return !item['isChecked'] && (item['reportType'] == null || item['reportType']!.isEmpty);
    });

    if (hasMissingReportType) {
      // Show error toast before async operation
      Toast.showErrorToast(
        title: 'Error reporting delivery',
        description: 'Please select a report type for each item that is not checked',
        context: context,
      );
      return;
    }

    final Map<String, dynamic> reportData = {
      'orderID': widget.orderId,
      'reportedItems': reportedItems,
      'description': reportDescription,
    };

    // Store necessary context-related actions before async
    final NavigatorState navigator = Navigator.of(context);
    final BuildContext currentContext = context;

    try {
      await DeliveryService().reportDelivery(reportData);

      // Pop the screen and show success toast
      navigator.pop();

      if (!currentContext.mounted) return;

      Toast.showSuccessToast(
        title: 'Delivery reported',
        description: 'Your report has been submitted successfully',
        context: currentContext,
      );
    } catch (error) {
      // Show error toast in case of failure
      Toast.showErrorToast(
        title: 'Error reporting delivery',
        description: 'An error occurred while reporting the delivery. Please try again later.',
        context: currentContext,
      );
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

  Future<void> handleSubmitReview(BuildContext context, orderId, itemId, rating, review) async {
    rating ??= 1;
    review ??= '';

    try {
      await CheckoutService().addReview(orderId, itemId, rating, review);

      if (!context.mounted) return;

      Toast.showSuccessToast(
        title: 'Review submitted',
        description: 'Your review has been submitted successfully',
        context: context,
      );
    } catch (error) {
      Toast.showErrorToast(
        title: 'Error submitting review',
        description: 'An error occurred while submitting your review. Please try again later.',
        context: context,
      );
      print('Error submitting review: $error');
    }
  }

  void openResolvedModal(BuildContext context, Map<dynamic, dynamic>? reportData) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
            topLeft: Radius.circular(0),
            topRight: Radius.circular(0),
        ),
      ),
      builder: (context) {
          return StatefulBuilder(
            builder:(BuildContext context, StateSetter setModalState) {
              return Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [],
                )
              );
            }
          );
      }
    );
  }

  void openReviewModal(BuildContext context, Map<dynamic, dynamic>? reviewData, String itemId) {
    final TextEditingController reviewController = TextEditingController();
    int initialRating = reviewData?['rating'] ?? 1;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 10.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Furniture Review',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Divider(thickness: 1, color: Colors.black26),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: reviewData != null
                            ? null // Disable tap if reviewData exists
                            : () {
                          // Update the rating inside modal state
                          setModalState(() {
                            initialRating = index + 1;
                          });
                        },
                        child: Icon(
                          index < initialRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 25,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  reviewData == null
                      ? TextFormField(
                      controller: reviewController,
                      decoration: const InputDecoration(
                        labelText: 'Review Description',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(8),
                      ),
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins_Regular',
                      ),
                    )
                      : Text(
                      reviewData['review'] ?? 'No review available',
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins_Regular',
                        color: Colors.black87,
                      ),
                    ),

                  // Conditionally display buttons if no reviewData exists
                  reviewData == null
                      ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Button(
                          text: "Submit",
                          width: 150,
                          onPressed: () {
                            // Handle submission
                            handleSubmitReview(
                              context,
                              widget.orderId,
                              itemId,
                              initialRating,
                              reviewController.text,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Button(
                          text: "Cancel",
                          color: AppColors.error,
                          width: 150,
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  )
                      : const SizedBox(),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
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
                              textAlign: TextAlign.justify,
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
                            if (_getCurrentStatus(_orderData!['completion_status']) == 'Arrived')
                              Checkbox(
                                value: item['isChecked'] ?? false,
                                onChanged: (bool? newValue) {
                                  setState(() {
                                    item['isChecked'] = newValue ?? false;
                                  });
                                },
                              ),
                            if (_getCurrentStatus(_orderData!['completion_status']) == 'Completed')
                              IconButton(
                                icon: const Icon(Icons.add_comment_outlined, size: 25),
                                onPressed: () {
                                  openReviewModal(context, item['review'], item['id']);
                                },
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Remarks',
                    style: TextStyle(fontSize: 16, fontFamily: 'Poppins_SemiBold'),
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    controller: _remarksController,
                    readOnly: true,
                    decoration: const InputDecoration(
                      hintText: 'Add any additional notes here',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_getCurrentStatus(_orderData!['completion_status']) == 'Arrived' || _getCurrentStatus(_orderData!['completion_status']) == 'Resolved')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Button(
                  text: 'Complete Order',
                  onPressed: () { _completeOrder(); },
                ),
              ),
            const SizedBox(height: 20),
            if (_getCurrentStatus(_orderData!['completion_status']) == 'Arrived')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Button(
                  text: 'Report Delivery',
                  color: AppColors.error,
                  onPressed: () {
                    _openReportDeliveryModal(context, _orderData!['items']);
                  },
                ),
              ),
            if (_getCurrentStatus(_orderData!['completion_status']) == 'Resolved')
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Button(
                  text: 'Resolved - Delivery Report',
                  color: AppColors.warning,
                  onPressed: () {

                  },
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
