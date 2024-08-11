import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:space_sculpt_mobile_app/src/services/delivery_service.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import '../../../routes.dart';
import '../../widgets/title.dart';

class DeliveryOrderDetails extends StatefulWidget {
  final String orderId;

  const DeliveryOrderDetails({super.key, required this.orderId});

  @override
  _DeliveryOrderDetailsState createState() => _DeliveryOrderDetailsState();
}

class _DeliveryOrderDetailsState extends State<DeliveryOrderDetails> {
  late DatabaseReference _dbRef;
  late User _currentUser;
  Map<dynamic, dynamic>? _orderData;
  Map<dynamic, dynamic>? _userData;
  Map<dynamic, dynamic>? _customerData;
  final DeliveryService _deliveryService = DeliveryService();
  final List<File> _selectedImages = [];

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
      _fetchCustomerData();
      setState(() {});
    }
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
    }
  }

  Future<void> _fetchCustomerData() async {
    final snapshot = await _dbRef.child('users/${_orderData!['user_id']}').get();
    if (snapshot.exists) {
      final customerData = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        _customerData = customerData;
      });
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

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Different buttons based on the current status of the order
  Widget _buildActionButton(String status, BuildContext context) {
    switch (status) {
      case 'Ready For Shipping':
        return Button(
          onPressed: () async {
            // Show the toast synchronously before the async operation
            Toast.showSuccessToast(
                title: "Success",
                description: "Status updated to Shipping",
                context: context
            );

            await DeliveryService().updateStatus(widget.orderId, 'Shipping');

            if (context.mounted) _reloadScreen();
          },
          text: 'Start Shipping',
        );
      case 'Shipping':
        return Button(
          onPressed: () async {
            Toast.showSuccessToast(
                title: "Success",
                description: "Status updated to Arrived",
                context: context
            );

            await DeliveryService().updateStatus(widget.orderId, 'Arrived');

            if (context.mounted) _reloadScreen();
          },
          text: 'Confirm Arrival',
        );
      case 'Arrived':
        return Column(
          children: [
            _buildImagePicker(),
            Button(
              onPressed: () async {
                if (_selectedImages.isEmpty) {
                  Toast.showErrorToast(
                      title: "Error",
                      description: "Please upload at least one image",
                      context: context
                  );
                  return;
                }

                Toast.showSuccessToast(
                    title: "Success",
                    description: "Status updated to Completed",
                    context: context
                );

                await DeliveryService().updateStatus(widget.orderId, 'Completed');
                // Save the images to your storage or database here
                await _uploadImages();

                if (context.mounted) _reloadScreen();
              },
              text: 'Complete Delivery',
            ),
          ],
        );
      case 'Completed':
        return Button(
          onPressed: () {
            // Logic to view order details
          },
          text: 'View Proof of Delivery',
        );
      default:
        return const Text('Unknown status');
    }
  }

  // Builds the image picker UI
  Widget _buildImagePicker() {
    return Column(
      children: [
        Button(
          onPressed: _pickImage,
          text: 'Upload Proof of Delivery',
        ),
        const SizedBox(height: 10),
        _selectedImages.isEmpty
            ? const Text('No images selected')
            : Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_selectedImages.length, (index) {
            return Stack(
              children: [
                Image.file(
                  _selectedImages[index],
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.red),
                    onPressed: () => _removeImage(index),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _uploadImages() async {
    // Implement your image upload logic here
    // For example, upload to Firebase Storage and save the URLs to your database
  }

  void _reloadScreen() {
    setState(() {
      _orderData = null;
      _userData = null;
      _customerData = null;
    });
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _orderData == null && _userData == null && _customerData == null
        ? const Center(child: CircularProgressIndicator())
    : SingleChildScrollView(
        child: Column(
          children: [
            const TitleBar(title: 'Order Details', hasBackButton: true),
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
                          Routes.deliveryOrderStatus, arguments: widget.orderId,
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.local_shipping_outlined,
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
                          '${_customerData?['name']}',
                          style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14.0,
                              fontFamily: 'Poppins_Bold'
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_customerData?['contact']}',
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
            const SizedBox(height: 10),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: _orderData == null
                    ? const CircularProgressIndicator()
                    : _orderData!.isEmpty
                    ? const Text('No order found')
                    : _buildActionButton(_getCurrentStatus(_orderData!['completion_status']), context),
            ),
          ]
        )
      ),
    );
  }
}
