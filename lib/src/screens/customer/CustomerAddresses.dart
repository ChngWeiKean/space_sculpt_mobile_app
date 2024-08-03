import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import '../../../colors.dart';
import '../../../routes.dart';
import '../../widgets/title.dart';

class CustomerAddresses extends StatefulWidget {
  const CustomerAddresses({super.key});

  @override
  _CustomerAddressesState createState() => _CustomerAddressesState();
}

class _CustomerAddressesState extends State<CustomerAddresses> {
  User? _currentUser;
  List<Map<dynamic, dynamic>> _addresses = [];
  late DatabaseReference _dbRef;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchAddresses();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
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

          setState(() {
            _addresses = addressesList;
          });
        } else {
          setState(() {
            _addresses = [];
          });
        }
      } catch (error) {
        setState(() {
          _hasError = true;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _showAddressDetails(Map<dynamic, dynamic> address) async {
    final result = await Navigator.pushNamed(
      context,
      Routes.customerAddressDetails,
      arguments: {
        'address': address,
      },
    );

    if (result == true) {
      _fetchAddresses();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TitleBar(title: 'My Addresses', hasBackButton: true),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? const Center(child: Text('Error loading addresses.'))
                : _addresses.isEmpty
                ? const Center(child: Text('No addresses found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(0.0),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final address = _addresses[index];
                return Column(
                  children: [
                    Container(
                      color: Colors.white,
                      child: ListTile(
                        title: Stack(
                          children: [
                            Text(address['name'],
                                style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Medium')),
                            if (address['isDefault'] == true)
                              const Positioned(
                                right: 0,
                                child: Badge(
                                  label: Text('DEFAULT',
                                      style: TextStyle(fontSize: 10, fontFamily: 'Poppins_Bold')),
                                  backgroundColor: AppColors.secondary,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Text(address['address'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Regular')),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 15),
                        onTap: () => _showAddressDetails(address),
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Button(
              text: 'Add New Address',
              onPressed: () => Navigator.pushNamed(context, Routes.customerAddNewAddress),
            ),
          ),
        ],
      ),
    );
  }
}
