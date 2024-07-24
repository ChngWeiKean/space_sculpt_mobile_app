import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_place/google_place.dart';
import '../../../colors.dart';
import '../../services/address_service.dart';
import '../../widgets/autocomplete.dart';
import '../../widgets/title.dart';
import '../../../keys.dart';

class CustomerAddressDetails extends StatefulWidget {
  final Map<dynamic, dynamic> address;

  const CustomerAddressDetails({required this.address, super.key});

  @override
  _CustomerAddressDetailsState createState() => _CustomerAddressDetailsState();
}

class _CustomerAddressDetailsState extends State<CustomerAddressDetails> {
  late GoogleMapController _mapController;
  late GooglePlace _googlePlace;
  LatLng? _initialPosition;
  bool _isDefault = false;
  final Set<Marker> _markers = {};
  bool _isDataLoaded = false;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _googlePlace = GooglePlace(googleMapsApiKey);
    _currentUser = FirebaseAuth.instance.currentUser;
    _fetchPlaceDetails();
  }

  Future<void> _fetchPlaceDetails() async {
    final addressMap = widget.address['address'] as Map<dynamic, dynamic>;
    final placeId = addressMap['place_id'];

    print('Place ID: $placeId');

    if (placeId != null && placeId is String) {
      final result = await _googlePlace.details.get(placeId);
      if (result != null && result.result != null) {
        final location = result.result!.geometry!.location!;
        setState(() {
          _initialPosition = LatLng(location.lat!, location.lng!);
          _markers.add(
            Marker(
              markerId: const MarkerId('initial_position'),
              position: _initialPosition!,
              infoWindow: const InfoWindow(title: 'Selected Place'),
            ),
          );
          _isDefault = addressMap['isDefault'] == true; // Set default status
          _isDataLoaded = true; // Data is loaded
        });
      } else {
        print('Place details could not be fetched.');
      }
    } else {
      print('Invalid place_id or place_id is null.');
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    if (_initialPosition != null) {
      _mapController.animateCamera(CameraUpdate.newLatLng(_initialPosition!));
    }
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
      });
    }
  }

  Future<void> _updateDefaultStatus(bool isDefault) async {
    final addressMap = widget.address['address'] as Map<dynamic, dynamic>;
    final addressId = addressMap['id'];
    final userId = _currentUser?.uid;
    if (addressId != null && userId != null) {
      await AddressService().updateDefaultAddress(userId, addressId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const TitleBar(title: 'Address Details', hasBackButton: true), // Use custom TitleBar
          Expanded(
            child: Stack(
              children: [
                if (_isDataLoaded)
                  GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: _initialPosition ?? const LatLng(0, 0),
                      zoom: 15,
                    ),
                    onMapCreated: _onMapCreated,
                    markers: _markers,
                  )
                else
                  const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Set this address as default?',
                          style: TextStyle(
                            fontFamily: 'Poppins_Bold',
                            fontSize: 16.0,
                          ),
                        ),
                      ),
                      Switch(
                        inactiveTrackColor: Colors.grey[300],
                        activeColor: AppColors.secondary,
                        value: _isDefault,
                        onChanged: (value) {
                          setState(() {
                            _isDefault = value;
                          });
                          _updateDefaultStatus(value);
                        },
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 40, // Adjusted to avoid overlapping with the switch row
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
        ],
      ),
    );
  }
}
