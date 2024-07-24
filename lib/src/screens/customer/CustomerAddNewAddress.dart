import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import 'package:space_sculpt_mobile_app/src/widgets/button.dart';
import 'package:space_sculpt_mobile_app/src/widgets/toast.dart';
import '../../../colors.dart';
import '../../services/address_service.dart';
import '../../widgets/autocomplete.dart';
import '../../widgets/title.dart';
import '../../../keys.dart';

class CustomerAddNewAddress extends StatefulWidget {
  const CustomerAddNewAddress({super.key});

  @override
  CustomerAddNewAddressState createState() => CustomerAddNewAddressState();
}

class CustomerAddNewAddressState extends State<CustomerAddNewAddress> {
  late GoogleMapController _mapController;
  late GooglePlace _googlePlace;
  final LatLng _initialPosition = const LatLng(5.4164, 100.3327); // Penang island coordinates
  final Set<Marker> _markers = {};
  User? _currentUser;

  String _name = '';
  String _address = '';
  String _placeId = '';

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(googleMapsApiKey);
    _currentUser = FirebaseAuth.instance.currentUser;
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition));
  }

  void _onAutocompleteSelected(AutocompletePrediction prediction) async {
    final details = await _googlePlace.details.get(prediction.placeId!);
    if (details != null && details.result != null) {
      final location = details.result!.geometry!.location!;
      setState(() {
        _markers.add(
          Marker(
            markerId: MarkerId(prediction.placeId!),
            position: LatLng(location.lat!, location.lng!),
            infoWindow: InfoWindow(title: prediction.description),
          ),
        );
        _mapController.animateCamera(CameraUpdate.newLatLng(LatLng(location.lat!, location.lng!)));

        // Store the necessary address details
        _name = details.result!.name!;
        _address = details.result!.formattedAddress!;
        _placeId = prediction.placeId!;
      });
    }
  }

  Future<void> _addNewAddress(BuildContext context) async {
    final userId = _currentUser?.uid;
    if (userId != null) {
      final newAddress = {
        'name': _name,
        'address': _address,
        'place_id': _placeId,
        'isDefault': false,
      };

      if (!context.mounted) return;

      if (_name == '' || _address == '' || _placeId == '') {
        Toast.showErrorToast(title: "Error", description: "Please select a valid address", context: context);
        return;
      }

      await AddressService().addAddress(userId, newAddress);

      if (!context.mounted) return;

      Toast.showSuccessToast(title: "Success", description: "Address added successfully", context: context);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(title: 'Add New Address', hasBackButton: true),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: 15,
                  ),
                  onMapCreated: _onMapCreated,
                  markers: _markers,
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: SizedBox(
                    height: 300,
                    child: GooglePlacesAutocomplete(
                      googlePlace: _googlePlace,
                      onSelected: _onAutocompleteSelected,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Button(
              onPressed: () => _addNewAddress(context),
              text: 'Add New Address',
            ),
          ),
        ],
      ),
    );
  }
}
