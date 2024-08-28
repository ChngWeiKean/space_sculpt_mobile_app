import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_place/google_place.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import '../../../colors.dart';
import '../../../routes.dart';
import '../../widgets/title.dart';
import '../../../keys.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CustomerCheckout extends StatefulWidget {
  final List<Map<dynamic, dynamic>> cartItems;

  const CustomerCheckout({super.key, required this.cartItems});

  @override
  _CustomerCheckoutState createState() => _CustomerCheckoutState();
}

class _CustomerCheckoutState extends State<CustomerCheckout> {
  User? _currentUser;
  Map<dynamic, dynamic> _userData = {};
  List<Map<dynamic, dynamic>> _addresses = [];
  List<Map<dynamic, dynamic>> _vouchers = [];
  Map<String, dynamic>? _settings;
  bool loading = true;
  late List<Map<dynamic, dynamic>> availableItems;
  Map<dynamic, dynamic>? _selectedVoucher;
  late DatabaseReference _dbRef;
  double? _distanceFromShop;
  String _shippingFee = '0.00';
  String _subtotal = '0.00';
  String _weightFee = '0.00';
  String _voucherDiscount = '0.00';
  String _total = '0.00';
  String? _selectedAddressId;
  String _selectedPaymentMethod = '';

  final GooglePlace _places = GooglePlace(googleMapsApiKey);

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _filterAvailableItems();
    _fetchData();
  }

  Future<void> _fetchData() async {
    await Future.wait([
      _fetchSettings(),
      _fetchUserData(),
      _fetchVouchers(),
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
    }
  }

  Future<void> _fetchSettings() async {
    setState(() {
      loading = true;
    });

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
          loading = false;

          // After fetching settings, fetch addresses
          _fetchAddresses();
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print('Error fetching settings: $e');
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      loading = true;
    });

    if (_currentUser != null) {
      try {
        final snapshot = await _dbRef.child('users/${_currentUser!.uid}/addresses').get();
        if (snapshot.exists) {
          final addressesData = snapshot.value as Map<dynamic, dynamic>;
          final addressesList = addressesData.entries.map((e) {
            final address = e.value as Map<dynamic, dynamic>;
            address['id'] = e.key; // Add the key as the 'id'
            return address;
          }).toList();

          // Sort addresses with 'isDefault' first
          addressesList.sort((a, b) {
            final isDefaultA = a['isDefault'] == true ? 1 : 0;
            final isDefaultB = b['isDefault'] == true ? 1 : 0;
            return isDefaultB.compareTo(isDefaultA);
          });

          final defaultAddress = addressesList.firstWhere((address) => address['isDefault'] == true, orElse: () => {});
          setState(() {
            _addresses = addressesList;
            _selectedAddressId = defaultAddress['id'];

            // Call _updateAddressData after addresses are fetched
            if (_settings != null && _addresses.isNotEmpty) {
              final defaultAddress = _addresses.firstWhere((address) => address['isDefault'] == true, orElse: () => {});
              final shopPlaceId = _settings!['address']?['place_id'] as String? ?? '';

              print('Default Address: ${defaultAddress['place_id']}');
              print('Shop Place ID: $shopPlaceId');

              if (defaultAddress.isNotEmpty && shopPlaceId.isNotEmpty) {
                _updateAddressData(defaultAddress['place_id'], shopPlaceId);
              }
            }
          });
        } else {
          setState(() {
            _addresses = [];
          });
        }
      } catch (error) {
        print('Error fetching addresses: $error');
        setState(() {
          loading = false;
        });
      }
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _fetchAddressDetails(String placeId, Function(DetailsResponse) callback) async {
    try {
      print('Fetching address details for place ID: $placeId');
      final result = await _places.details.get(placeId);
      print('Result: $result');
      // Check if the result is not null and contains the expected data
      if (result != null) {
        callback(result);
      } else {
        print('Error fetching address details: MEOW');
      }
    } catch (e) {
      print('Exception occurred while fetching address details: $e');
    }
  }

  Future<void> _calculateShippingFee(double distance) async {
    if (_settings == null) return;

    final settings = _settings!;
    final standardShippingFee = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'standard_shipping_fee')['value']);
    final shippingFeeThreshold = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'shipping_fee_threshold')['value']);
    final distanceThresholdForStandardDeliveryFee = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'distance_threshold_for_standard_delivery_fee')['value']);
    final extraDeliveryChargesPerKilometer = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'extra_delivery_charges_per_kilometer')['value']);

    print('Standard Shipping Fee: $standardShippingFee');
    print('Shipping Fee Threshold: $shippingFeeThreshold');
    print('Distance Threshold for Standard Delivery Fee: $distanceThresholdForStandardDeliveryFee');
    print('Extra Delivery Charges Per Kilometer: $extraDeliveryChargesPerKilometer');
    print('Distance in calc shipping fee: $distance');
    double shippingFee;

    // Calculate shipping fee based on distance
    if (distance > distanceThresholdForStandardDeliveryFee) {
      print('Distance is greater than threshold');
      shippingFee = standardShippingFee +
          ((distance - distanceThresholdForStandardDeliveryFee) *
              extraDeliveryChargesPerKilometer);
    } else {
      print('Distance is less than threshold');
      shippingFee = standardShippingFee;
    }

    setState(() {
      // Update state with the calculated shipping fee
      _shippingFee = shippingFee.toStringAsFixed(2);
    });

    await _calculateWeightFee();

    print('Calculated Shipping Fee: $_shippingFee');
  }

  Future<void> _calculateWeightFee() async {
    if (_settings == null) return;

    // Get widget.cartItems and calculate total weight
    double weight = 0.0;
    for (var item in widget.cartItems) {
      final weightValue = double.parse(item['weight']);
      final quantity = int.parse(item['quantity'].toString());
      weight += weightValue * quantity;
    }

    final settings = _settings!;
    final maximumWeightLoad = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'maximum_weight_load')['value']);
    final extraWeightFeePerKilogram = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'extra_weight_fee_per_kilogram')['value']);

    double weightFee = 0.0;

    if (weight > maximumWeightLoad) {
      weightFee = (weight - maximumWeightLoad) * extraWeightFeePerKilogram;
    } else {
      weightFee = 0.0;
    }

    setState(() {
      _weightFee = weightFee.toStringAsFixed(2);
    });

    print('Weight Fee: $_weightFee');

    await _calculateSubtotal();
  }

  Future<void> _calculateSubtotal() async {
    if (_settings == null) return;

    final settings = _settings!;
    final shippingFeeThreshold = double.parse(settings['settings']
        .firstWhere((setting) => setting['key'] == 'shipping_fee_threshold')['value']);

    double subtotal = 0.0;
    for (var item in widget.cartItems) {
      final price = double.parse(item['discounted_price'] ?? item['price']);
      final quantity = int.parse(item['quantity'].toString());
      subtotal += price * quantity;
    }

    if (subtotal > shippingFeeThreshold) {
      setState(() {
        _shippingFee = '0.00';
      });
    }

    setState(() {
      _subtotal = subtotal.toStringAsFixed(2);
    });
    print('Subtotal: $_subtotal');

    await _calculateTotal();
  }

  Future<void> _calculateTotal() async {
    if (_settings == null) return;

    double total = 0.0;

    // Calculate total based on subtotal, shipping fee, weight fee, and voucher discount
    total = double.parse(_subtotal) + double.parse(_shippingFee) + double.parse(_weightFee) - double.parse(_voucherDiscount);

    setState(() {
      _total = total.toStringAsFixed(2);
    });

    print('Total: $_total');
  }

  Future<void> _fetchDistanceAndDuration(LatLng origin, LatLng destination) async {
    const apiKey = googleMapsApiKey;  // Replace with your Google Maps API key
    final url = Uri.https(
      'maps.googleapis.com',
      '/maps/api/distancematrix/json',
      {
        'origins': '${origin.latitude},${origin.longitude}',
        'destinations': '${destination.latitude},${destination.longitude}',
        'key': apiKey,
      },
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Check if the response contains valid data
        if (data['status'] == 'OK') {
          final rows = data['rows'] as List<dynamic>;
          if (rows.isNotEmpty) {
            final elements = rows[0]['elements'] as List<dynamic>;
            if (elements.isNotEmpty) {
              final element = elements[0];
              final distance = element['distance']['text'];
              final duration = element['duration']['text'];
              final distanceValue = element['distance']['value']?.toDouble() / 1000 ?? 0.0;
              print('Distance Value: $distanceValue');

              setState(() {
                _distanceFromShop = distanceValue;
              });

              _calculateShippingFee(distanceValue);
            } else {
              print('No elements found in the response.');
            }
          } else {
            print('No rows found in the response.');
          }
        } else {
          print('Error in response status: ${data['status']}');
        }
      } else {
        print('Failed to fetch distance and duration. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception occurred while fetching distance and duration: $e');
    }
  }

  Future<void> _updateAddressData(String userAddressId, String shopAddressId) async {
    // Fetch address details for the user
    _fetchAddressDetails(userAddressId, (userPlace) {
      // Fetch address details for the shop
      _fetchAddressDetails(shopAddressId, (shopPlace) {
        setState(() {
          // Extract user and shop locations, providing default values if needed
          final userLocation = LatLng(
            userPlace.result?.geometry?.location?.lat ?? 0.0,  // Provide default value if null
            userPlace.result?.geometry?.location?.lng ?? 0.0,  // Provide default value if null
          );
          final shopLocation = LatLng(
            shopPlace.result?.geometry?.location?.lat ?? 0.0,  // Provide default value if null
            shopPlace.result?.geometry?.location?.lng ?? 0.0,  // Provide default value if null
          );

          // Fetch distance and duration
          _fetchDistanceAndDuration(userLocation, shopLocation).then((_) {
            // Extract distance from state (should be set in _fetchDistanceAndDuration)
            double distanceFromShop = _distanceFromShop ?? 0.0; // Default to 0.0 if null

            // Calculate shipping fee
            final shippingFee = _calculateShippingFee(distanceFromShop);
            print('Shipping Fee: $shippingFee');
          });
        });
      });
    });
  }

  Future<void> _fetchVouchers() async {
    setState(() {
      loading = true;
    });

    if (_currentUser != null) {
      try {
        final snapshot = await _dbRef.child('users/${_currentUser!.uid}/vouchers').get();
        if (snapshot.exists) {
          final vouchersData = snapshot.value as Map<dynamic, dynamic>;
          final validVouchers = vouchersData.entries
              .where((e) => e.value == true)
              .map((e) => e.key)
              .toList();

          List<Map<dynamic, dynamic>> vouchersList = [];
          for (var voucherId in validVouchers) {
            final voucherSnapshot = await _dbRef.child('vouchers/$voucherId').get();
            if (voucherSnapshot.exists) {
              final voucherData = voucherSnapshot.value as Map<dynamic, dynamic>;
              voucherData['id'] = voucherId;
              vouchersList.add(voucherData);
            }
          }

          setState(() {
            _vouchers = vouchersList;
          });
        } else {
          setState(() {
            _vouchers = [];
          });
        }
      } catch (error) {
        setState(() {
          print('Error fetching settings: $error');
          loading = false;
        });
      }
    }

    setState(() {
      loading = false;
    });
  }

  Map<String, dynamic> handleVoucherUsageValidation(Map<dynamic, dynamic> voucher) {
    if (voucher != null) {
      if (double.parse(voucher['minimum_spend']) > double.parse(_subtotal)) {
        return {'valid': false, 'message': 'Minimum spend of RM${voucher['minimum_spend']} is required to use this voucher.'};
      }
      if (DateTime.parse(voucher['expiry_date']).isBefore(DateTime.now())) {
        return {'valid': false, 'message': 'This voucher has expired.'};
      }
      if (voucher['customer_eligibility'] == 'new' && _userData['orders'].isNotEmpty) {
        return {'valid': false, 'message': 'This voucher is only valid for new customers.'};
      }
      if (voucher['deleted'] == true) {
        return {'valid': false, 'message': 'This voucher has been deleted.'};
      }
      return {'valid': true, 'message': null};
    } else {
      return {'valid': false, 'message': 'Please select a valid voucher.'};
    }
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
                    _userData['name'],
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
                    _userData['email'],
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
                    _userData['contact'],
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

  void _openVoucherSelectionModal() {
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
          builder: (BuildContext context, StateSetter setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(0.0),
                      itemCount: _vouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _vouchers[index];
                        final isSelected = _selectedVoucher?['id'] == voucher['id'];
                        final validation = handleVoucherUsageValidation(voucher);
                        final isValid = validation['valid'];
                        final validationMessage = validation['message'];

                        return Column(
                          children: [
                            ListTile(
                              leading: voucher['discount_application'] == 'products'
                                  ? const Icon(Icons.discount_outlined, size: 32, color: AppColors.secondary)
                                  : const Icon(Icons.local_shipping_outlined, size: 32, color: AppColors.secondary),
                              title: Text(voucher['voucher_code']),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(voucher['discount_type'] == 'fixed'
                                          ? 'RM ${voucher['discount_value']}'
                                          : '${voucher['discount_value']}%'),
                                      const SizedBox(width: 10),
                                      Text(voucher['discount_application'] == 'products'
                                          ? "Products Discount"
                                          : "Shipping Discount"),
                                    ],
                                  ),
                                  if (!isValid)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        validationMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: Icon(
                                  isSelected ? Icons.check_circle : Icons.circle,
                                  color: isSelected ? Colors.blue : Colors.grey,
                                ),
                                onPressed: isValid
                                    ? () {
                                  setState(() {
                                    _selectedVoucher = voucher;
                                    _calculateTotal();
                                  });
                                }
                                    : null,
                              ),
                              tileColor: isSelected
                                  ? Colors.blue.withOpacity(0.2)
                                  : isValid
                                  ? Colors.transparent
                                  : Colors.grey.withOpacity(0.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: isSelected ? Colors.blue : Colors.transparent,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Button(
                    onPressed: () => Navigator.pop(context),
                    text: _selectedVoucher != null ? 'Apply Voucher' : 'Close',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _selectPaymentMethod(String method) {
    setState(() {
      _selectedPaymentMethod = method;
    });
  }

  void _filterAvailableItems() {
    availableItems = widget.cartItems.where((item) {
      return int.parse(item['inventory'].toString()) > 0;
    }).toList();
  }

  void _handlePayment(BuildContext context) {
    if (_selectedPaymentMethod.isEmpty) {
      Toast.showErrorToast(title: 'Error', description: 'Please select a payment method.', context: context);
      return;
    }

    if (_selectedAddressId == null) {
      Toast.showErrorToast(title: 'Error', description: 'Please select an address.', context: context);
      return;
    }

    if (availableItems.isEmpty) {
      Toast.showErrorToast(title: 'Error', description: 'No items available for checkout.', context: context);
      return;
    }

    final checkoutData = {
      'user': _userData,
      'address': _addresses.firstWhere((address) => address['id'] == _selectedAddressId),
      'items': availableItems,
      'subtotal': _subtotal,
      'shipping': _shippingFee,
      'weight': _weightFee,
      'discount': _voucherDiscount,
      'total': _total,
      'payment': _selectedPaymentMethod,
      'voucher': _selectedVoucher,
    };

    print('Checkout Data: ${checkoutData['items']}');

    Navigator.pushNamed(context, Routes.customerPayment, arguments: checkoutData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const TitleBar(title: 'Checkout', hasBackButton: true),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _addresses.length,
                            itemBuilder: (context, index) {
                              final address = _addresses[index];
                              final isSelected = _selectedAddressId == address['id'];
                              return GestureDetector(
                                onTap: () {
                                  final shopPlaceId = _settings!['address']?['place_id'] as String? ?? '';
                                  _updateAddressData(address['place_id'], shopPlaceId);
                                  setState(() {
                                    _selectedAddressId = address['id'];
                                  });
                                },
                                child: Container(
                                  width: 200,
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected ? Colors.blue : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              address['name'],
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontFamily: 'Poppins_Bold',
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.blue,
                                              size: 16,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        address['address'],
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'Poppins_Regular',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.all(0.0),
                          physics: const NeverScrollableScrollPhysics(), // Disable scrolling for the list
                          shrinkWrap: true, // Make the list take only the space it needs
                          itemCount: availableItems.length,
                          itemBuilder: (context, index) {
                            final item = availableItems[index];
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
                              'Select Payment Method',
                              style: TextStyle(fontSize: 16, fontFamily: 'Poppins_Semibold'),
                            ),
                            const SizedBox(height: 5),
                            GestureDetector(
                              onTap: () => _selectPaymentMethod('Credit/Debit Card'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _selectedPaymentMethod == 'Credit/Debit Card' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                  border: Border.all(
                                    color: _selectedPaymentMethod == 'Credit/Debit Card' ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.credit_card,
                                      color: _selectedPaymentMethod == 'Credit/Debit Card' ? Colors.black : Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Credit/Debit Card',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins_Medium',
                                          color: _selectedPaymentMethod == 'Credit/Debit Card' ? Colors.blue : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (_selectedPaymentMethod == 'Credit/Debit Card')
                                      const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _selectPaymentMethod('Touch \'n Go'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPaymentMethod == 'Touch \'n Go' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                  border: Border.all(
                                    color: _selectedPaymentMethod == 'Touch \'n Go' ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.account_balance_wallet_outlined,
                                      color: _selectedPaymentMethod == 'Touch \'n Go' ? Colors.black : Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Touch 'n Go",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins_Medium',
                                          color: _selectedPaymentMethod == 'Touch \'n Go' ? Colors.blue : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (_selectedPaymentMethod == 'Touch \'n Go')
                                      const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                                  ],
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _selectPaymentMethod('Cash on Delivery'),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: _selectedPaymentMethod == 'Cash on Delivery' ? Colors.blue.withOpacity(0.2) : Colors.transparent,
                                  border: Border.all(
                                    color: _selectedPaymentMethod == 'Cash on Delivery' ? Colors.blue : Colors.grey,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.monetization_on_outlined,
                                      color: _selectedPaymentMethod == 'Cash on Delivery' ? Colors.black : Colors.blue,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Cash on Delivery',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontFamily: 'Poppins_Medium',
                                          color: _selectedPaymentMethod == 'Cash on Delivery' ? Colors.blue : Colors.black,
                                        ),
                                      ),
                                    ),
                                    if (_selectedPaymentMethod == 'Cash on Delivery')
                                      const Icon(Icons.check_circle, color: Colors.blue, size: 18),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _openVoucherSelectionModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _selectedVoucher != null
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedVoucher?['voucher_code'],
                                      style: const TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(_selectedVoucher?['discount_type'] == 'fixed'
                                            ? 'RM ${_selectedVoucher?['discount_value']}'
                                            : '${_selectedVoucher?['discount_value']}%'),
                                        const SizedBox(width: 10),
                                        Text(_selectedVoucher?['discount_application'] == 'products'
                                            ? "Products Discount"
                                            : "Shipping Discount"),
                                      ],
                                    ),
                                  ],
                                )
                                    : const Text(
                                  'Select Voucher',
                                  style: TextStyle(fontSize: 14, fontFamily: 'Poppins_Medium'),
                                ),
                                const Icon(Icons.keyboard_arrow_right_rounded),
                              ],
                            ),
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
                                  'RM $_subtotal',
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
                                  'RM $_weightFee',
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
                                  'RM $_shippingFee',
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
                                  '- RM $_voucherDiscount',
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
                                  'RM $_total',
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
                    Text('Total: RM $_total', style: const TextStyle(
                      fontFamily: 'Poppins_Semibold',
                      fontSize: 16,
                    )),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => _handlePayment(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 16),
                      ),
                      child: const Text(
                        'Proceed to Payment',
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
        ]
      )
    );
  }

}