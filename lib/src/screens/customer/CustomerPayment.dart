import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import '../../../colors.dart';
import '../../../routes.dart';
import '../../services/checkout_service.dart';
import '../../widgets/title.dart';
import '../../widgets/toast.dart';

class CustomerPayment extends StatefulWidget {
  final Map<String, dynamic> checkoutData;

  const CustomerPayment({super.key, required this.checkoutData});

  @override
  _CustomerPaymentState createState() => _CustomerPaymentState();
}

class _CustomerPaymentState extends State<CustomerPayment> {
  User? _currentUser;
  String? _selectedTime;
  late DatabaseReference _dbRef;
  Map<String, dynamic>? _settings;
  List<String> _timeOptions = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderNameController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _billingAddressController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    try {
      final snapshot = await _dbRef.child('settings').get();
      if (snapshot.exists) {
        final settingsData = snapshot.value as Map<dynamic, dynamic>;

        // Create settings list from key-value pairs
        final settingsList = settingsData.entries.map((entry) {
          return {
            'key': entry.key,
            'value': entry.value,
          };
        }).toList();

        // Extract the address object if it exists
        final address = settingsData.containsKey('address') ? settingsData['address'] as Map<dynamic, dynamic> : null;

        setState(() {
          _settings = {
            'settings': settingsList,
            'address': address != null ? Map<String, dynamic>.from(address) : null,
          };

          print('Settings: $_settings');
          _generateTimeOptions();
        });
      }
    } catch (e) {
      print('Error fetching settings: $e');
    }
  }

  void _generateTimeOptions() {
    if (_settings == null) {
      print('Settings are null');
      return;
    }

    final settingsList = _settings!['settings'] as List<Map<String, dynamic>>;
    final startTime = settingsList.firstWhere((s) => s['key'] == 'initial_delivery_time', orElse: () => {'value': '00:00 AM'})['value'] as String?;
    final endTime = settingsList.firstWhere((s) => s['key'] == 'end_delivery_time', orElse: () => {'value': '23:59 PM'})['value'] as String?;

    if (startTime == null || endTime == null) {
      print('Start time or end time is null');
      return;
    }

    print('Start Time: $startTime');
    print('End Time: $endTime');

    const interval = 60;

    final times = <String>[];
    DateTime start = _parseTime(startTime);
    final DateTime end = _parseTime(endTime);

    while (start.isBefore(end) || start.isAtSameMomentAs(end)) {
      times.add(_formatTime(start));
      start = start.add(const Duration(minutes: interval));
    }

    setState(() {
      _timeOptions = times;
    });
    print('Time options: $_timeOptions');
  }

  DateTime _parseTime(String timeString) {
    if (timeString == null || timeString.isEmpty) {
      print('Error: timeString is null or empty');
      return DateTime.now(); // Return a default value or handle the error
    }

    final timeStringLower = timeString.toLowerCase();
    final period = timeStringLower.contains('pm') ? 'PM' : 'AM';
    final time = timeStringLower.replaceAll(RegExp(r'(am|pm)', caseSensitive: false), '').trim();

    final timeParts = time.split(':');
    final hours = int.parse(timeParts[0]);
    final minutes = timeParts.length > 1 ? int.parse(timeParts[1]) : 0;

    int adjustedHours = hours;
    if (period == 'PM' && hours < 12) {
      adjustedHours += 12;
    }
    if (period == 'AM' && hours == 12) {
      adjustedHours = 0;
    }

    return DateTime(0, 1, 1, adjustedHours, minutes);
  }

  String _formatTime(DateTime date) {
    final hours = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minutes = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hours:$minutes $period';
  }

  void _validateDateTime(BuildContext context) {
    if (_settings == null) {
      print('Settings are null');
      return;
    }

    final settingsList = _settings!['settings'] as List<Map<String, dynamic>>;
    final offset = settingsList.firstWhere((s) => s['key'] == 'delivery_offset', orElse: () => {'value': '0'})['value'] as String;
    print('Offset: $offset');
    final selectedDate = DateFormat('yyyy-MM-dd').parse(_dateController.text);
    final today = DateTime.now();
    final deliveryDate = today.add(Duration(days: int.parse(offset)));

    if (selectedDate.isBefore(deliveryDate)) {
      Toast.showErrorToast(title: 'Invalid Delivery Date',
          description: 'Please select a shipping date at least $offset days from today',
          context: context);
    } else {
      Navigator.pop(context);
    }
  }

  void _handlePlaceOrder(BuildContext context) async {
    // validate all the fields
    if (widget.checkoutData['payment'] == 'Credit/Debit Card') {
      if (_cardHolderNameController.text.isEmpty) {
        Toast.showErrorToast(title: 'Error', description: 'Please enter the card holder name', context: context);
        return;
      }

      if (_cardNumberController.text.isEmpty) {
        Toast.showErrorToast(title: 'Error', description: 'Please enter the card number', context: context);
        return;
      }

      if (_expiryDateController.text.isEmpty) {
        Toast.showErrorToast(title: 'Error', description: 'Please enter the expiry date', context: context);
        return;
      }

      if (_cvvController.text.isEmpty) {
        Toast.showErrorToast(title: 'Error', description: 'Please enter the CVV', context: context);
        return;
      }

      if (_billingAddressController.text.isEmpty) {
        Toast.showErrorToast(title: 'Error', description: 'Please enter the billing address', context: context);
        return;
      }
    }

    if (_dateController.text.isEmpty) {
      Toast.showErrorToast(title: 'Error', description: 'Please select a shipping date', context: context);
      return;
    }

    if (_selectedTime == null) {
      Toast.showErrorToast(title: 'Error', description: 'Please select a shipping time', context: context);
      return;
    }

    final String payment;
    final String paymentMethod;
    if (widget.checkoutData['payment'] == 'Credit/Debit Card') {
      payment = 'card';
      paymentMethod = 'Credit/Debit Card';
    } else if (widget.checkoutData['payment'] == 'Cash on Delivery') {
      payment = 'cash';
      paymentMethod = 'Cash on Delivery';
    } else {
      payment = 'ewallet';
      paymentMethod = 'E-Wallet';
    }

    // Handle the payment process
    final data = {
      'user': _currentUser!.uid,
      'address': widget.checkoutData['address'],
      'items': widget.checkoutData['items'],
      'payment': payment,
      'payment_method': paymentMethod,
      'subtotal': widget.checkoutData['subtotal'],
      'shipping': widget.checkoutData['shipping'],
      'weight': widget.checkoutData['weight'],
      'discount': widget.checkoutData['discount'],
      'voucher': widget.checkoutData['voucher'],
      'total': widget.checkoutData['total'],
      'shipping_date': _dateController.text,
      'shipping_time': _selectedTime,
      'remarks': _remarksController.text,
    };

    for (var item in data['items']) {
      print(item['variantId'].toString());
    }
    await CheckoutService().placeOrder(data);

    if (!context.mounted) return;

    Toast.showSuccessToast(title: 'Success', description: 'Order placed successfully', context: context);

    Navigator.pushNamed(context, Routes.homepage);
  }

  void _openCreditCardPaymentModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Text(
                    'Enter Credit Card Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your card number';
                      } else if (value.length != 16) {
                        return 'Card number must be 16 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _cardHolderNameController,
                    decoration: const InputDecoration(
                      labelText: 'Card Holder Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the card holder name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextFormField(
                          controller: _expiryDateController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry Date (MM/YY)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.datetime,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the expiry date';
                            } else if (!RegExp(r'^(0[1-9]|1[0-2])\/?([0-9]{2})$').hasMatch(value)) {
                              return 'Enter a valid expiry date';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter the CVV';
                            } else if (value.length != 3) {
                              return 'CVV must be 3 digits';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _billingAddressController,
                    decoration: const InputDecoration(
                      labelText: 'Billing Address',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the billing address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Button(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        // Handle the payment process
                        Navigator.pop(context);
                      }
                    },
                    text: 'Confirm',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openShippingDateTimeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Text(
                      'Select Shipping Date & Time',
                      style: TextStyle(
                          fontSize: 18, fontFamily: 'Poppins_Semibold'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        labelText: 'Select Date',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true,
                      onTap: () async {
                        DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(Duration(days: int.parse(_settings!['settings']
                              .firstWhere((s) => s['key'] == 'delivery_offset', orElse: () => {'value': '0'})['value'] as String))),
                          firstDate: DateTime.now().add(Duration(days: int.parse(_settings!['settings']
                              .firstWhere((s) => s['key'] == 'delivery_offset', orElse: () => {'value': '0'})['value'] as String))),
                          lastDate: DateTime(2101),
                        );
                        if (pickedDate != null) {
                          _dateController.text =
                              DateFormat('yyyy-MM-dd').format(pickedDate);
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Select Time',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTime, // Initialize with the selected time
                      items: _timeOptions.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setModalState(() {
                          _selectedTime = newValue!;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a time';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Button(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _validateDateTime(context);
                        }
                      },
                      text: 'Confirm',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openContactInformationModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(0),
          topRight: Radius.circular(0),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const Center(
                child: Text(
                  'Contact Information',
                  style: TextStyle(fontSize: 18, fontFamily: 'Poppins_Semibold'),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.person, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.checkoutData['user']['name']}',
                    style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Regular'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.email, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.checkoutData['user']['email']}',
                    style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Regular'),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Icon(Icons.phone, color: Colors.blue),
                  const SizedBox(width: 10),
                  Text(
                    '${widget.checkoutData['user']['contact']}',
                    style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Regular'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const TitleBar(title: 'Payment', hasBackButton: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          height: 80.0,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.checkoutData['address']['name'],
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins_Bold',
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.blue,
                                    size: 16,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.checkoutData['address']['address'],
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontFamily: 'Poppins_Regular',
                                ),
                              ),
                            ],
                          ),
                        ),
                        ListView.builder(
                          physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the list
                          shrinkWrap: true, // Make the list take only the space it needs
                          itemCount: widget.checkoutData['items'].length,
                          itemBuilder: (context, index) {
                            final item = widget.checkoutData['items'][index];
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
                                            fontSize: 16,
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
                                          fontSize: 14,
                                          fontFamily: 'Poppins_SemiBold',
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          item['discounted_price'] != null
                                              ? Row(
                                            children: [
                                              Text(
                                                'RM ${item['discounted_price']}',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins_Medium',
                                                  fontSize: 13,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'RM ${item['price']}',
                                                style: const TextStyle(
                                                  fontFamily: 'Poppins_Medium',
                                                  fontSize: 11,
                                                  color: Colors.red,
                                                  decoration: TextDecoration.lineThrough,
                                                ),
                                              ),
                                            ],
                                          )
                                              : Text(
                                            'RM ${item['price']}',
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
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Payment Method',
                              style: TextStyle(fontSize: 16, fontFamily: 'Poppins_SemiBold'),
                            ),
                            const SizedBox(height: 5),
                            widget.checkoutData['payment'] == 'Credit/Debit Card'
                                ? GestureDetector(
                              onTap: () => _openCreditCardPaymentModal(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.2),
                                  border: Border.all(
                                    color: Colors.blue,
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Credit/Debit Card',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins_Medium',
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_right_rounded, color: Colors.blue),
                                  ],
                                ),
                              ),
                            )
                                : Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.blue,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    widget.checkoutData['payment'] == 'Cash on Delivery'
                                        ? Icons.monetization_on_outlined
                                        : Icons.account_balance_wallet_outlined,
                                    color: Colors.black,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      '${widget.checkoutData['payment']}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontFamily: 'Poppins_Medium',
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shipping Date & Time',
                              style: TextStyle(fontSize: 16, fontFamily: 'Poppins_SemiBold'),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () => _openShippingDateTimeModal(context),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.local_shipping_outlined,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        widget.checkoutData['shipping_date'] != null
                                            ? '${widget.checkoutData['shipping_date']} ${widget.checkoutData['shipping_time']}'
                                            : 'Select Shipping Date & Time',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins_Medium',
                                        ),
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_right_rounded),
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Remarks',
                              style: TextStyle(fontSize: 16, fontFamily: 'Poppins_SemiBold'),
                            ),
                            const SizedBox(height: 5),
                            TextFormField(
                              controller: _remarksController,
                              decoration: const InputDecoration(
                                hintText: 'Add any additional notes here',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              widget.checkoutData['voucher'] != null
                                  ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.checkoutData['voucher']['code'],
                                    style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(widget.checkoutData['voucher']['discount_type'] == 'fixed'
                                          ? 'RM ${widget.checkoutData['voucher']['discount_value']}'
                                          : '${widget.checkoutData['voucher']['discount_value']}%'),
                                      const SizedBox(width: 10),
                                      Text(widget.checkoutData['voucher']['discount_application'] == 'products'
                                          ? "Products Discount"
                                          : "Shipping Discount"),
                                    ],
                                  ),
                                ],
                              )
                                  : const Text('No Voucher Applied', style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium')),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal',
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                                Text(
                                  'RM ${widget.checkoutData['subtotal']}',
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
                                  'RM ${widget.checkoutData['weight']}',
                                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Shipping Fee',
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                                Text(
                                  'RM ${widget.checkoutData['shipping']}',
                                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Voucher Discount',
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                                Text(
                                  'RM ${widget.checkoutData['discount']}',
                                  style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                              ],
                            ),
                            const Divider(
                              thickness: 1,
                              color: Colors.grey,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(fontSize: 16, fontFamily: 'Poppins_Bold'),
                                ),
                                Text(
                                  'RM ${widget.checkoutData['total']}',
                                  style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Bold'),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _openContactInformationModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'View Contact Information',
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                                Icon(Icons.keyboard_arrow_right_rounded),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
              child: Container(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8, left: 8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text('Total: RM ${widget.checkoutData['total']}', style: const TextStyle(
                      fontFamily: 'Poppins_Semibold',
                      fontSize: 16,
                    )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _handlePlaceOrder(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      child: const Text(
                        'Place Order',
                        style: TextStyle(
                          fontFamily: 'Poppins_Bold',
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}