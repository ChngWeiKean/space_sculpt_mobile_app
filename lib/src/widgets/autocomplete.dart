import 'package:flutter/material.dart';
import 'package:google_place/google_place.dart';

class GooglePlacesAutocomplete extends StatefulWidget {
  final GooglePlace googlePlace;
  final Function(AutocompletePrediction) onSelected;

  const GooglePlacesAutocomplete({required this.googlePlace, required this.onSelected, super.key});

  @override
  _AutocompleteState createState() => _AutocompleteState();
}

class _AutocompleteState extends State<GooglePlacesAutocomplete> {
  final TextEditingController _controller = TextEditingController();
  List<AutocompletePrediction> _predictions = [];
  bool _isListVisible = false;

  void _onSearchChanged() async {
    final results = await widget.googlePlace.autocomplete.get(_controller.text);
    setState(() {
      _predictions = results?.predictions ?? [];
      _isListVisible = _predictions.isNotEmpty;
    });
  }

  void _onPredictionSelected(AutocompletePrediction prediction) {
    widget.onSelected(prediction);
    _controller.clear();
    setState(() {
      _predictions.clear();
      _isListVisible = false; // Hide the prediction list after selection
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0), // Add padding around the column
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: 'Search places...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              suffixIcon: const Icon(Icons.search),
            ),
            onChanged: (value) => _onSearchChanged(),
          ),
          const SizedBox(height: 8.0), // Space between the TextField and ListView
          if (_isListVisible) // Show the list only when it's visible
            Expanded(
              child: Container(
                color: Colors.white, // White background for the prediction list
                child: ListView.builder(
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      title: Text(prediction.description ?? ''),
                      onTap: () => _onPredictionSelected(prediction),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
