import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import '../../../colors.dart';
import '../../../routes.dart';
import '../../services/voucher_service.dart';
import '../../widgets/title.dart';

class CustomerVouchers extends StatefulWidget {
  const CustomerVouchers({super.key});

  @override
  _CustomerVouchersState createState() => _CustomerVouchersState();
}

class _CustomerVouchersState extends State<CustomerVouchers> {
  User? _currentUser;
  List<Map<dynamic, dynamic>> _vouchers = [];
  late DatabaseReference _dbRef;
  bool _isLoading = true;
  bool _hasError = false;
  final TextEditingController _voucherCodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _dbRef = FirebaseDatabase.instance.ref();
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchVouchers();
  }

  Future<void> _fetchVouchers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
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
          _hasError = true;
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _redeemVoucher(BuildContext context) async {
    final voucherCode = _voucherCodeController.text.trim();
    if (voucherCode.isEmpty || _currentUser == null) return;

    try {
      await VoucherService().redeemVoucher(_currentUser!.uid, voucherCode);

      if (!context.mounted) return;

      // Show success toast
      Toast.showSuccessToast(title: 'Success', description: 'Voucher redeemed successfully.', context: context);
    } catch (error) {

      if (!context.mounted) return;

      // Handle any errors
      Toast.showErrorToast(title: 'Error', description: "Invalid voucher code", context: context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const TitleBar(title: 'My Vouchers', hasBackButton: true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _voucherCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter voucher code',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _redeemVoucher(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  child: const Text('Redeem', style: TextStyle(fontFamily: 'Poppins_Medium', color: Colors.white)),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                ? const Center(child: Text('Error loading vouchers.'))
                : _vouchers.isEmpty
                ? const Center(child: Text('No vouchers found.'))
                : ListView.builder(
              padding: const EdgeInsets.all(0.0),
              itemCount: _vouchers.length,
              itemBuilder: (context, index) {
                final voucher = _vouchers[index];
                return ExpansionTile(
                  title: Row(
                    children: [
                      Column(
                        children: [
                          Icon(
                            voucher['discount_application'] == 'products'
                                ? Icons.shopping_bag
                                : Icons.local_shipping,
                            color: AppColors.secondary,
                            size: 48,
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  voucher['discount_type'] == 'fixed'
                                      ? 'RM${voucher['discount_value']}'
                                      : '${voucher['discount_value']}%',
                                  style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Medium'),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  voucher['discount_application'] == 'product'
                                      ? 'Product Discount'
                                      : 'Shipping Discount',
                                  style: const TextStyle(fontSize: 16, fontFamily: 'Poppins_Medium'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Min Spend: RM${voucher['minimum_spend']}',
                                  style: const TextStyle(fontSize: 13, fontFamily: 'Poppins_Regular'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Expiry Date: ${voucher['expiry_date']}',
                              style: const TextStyle(fontSize: 13, fontFamily: 'Poppins_Regular'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        voucher['terms_and_conditions'],
                        style: const TextStyle(fontSize: 12, fontFamily: 'Poppins_Regular'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
