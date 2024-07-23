import 'package:flutter/material.dart';

class TitleWithSearchAndFilter extends StatelessWidget {
  final bool hasBackButton;
  final void Function(String) onSearch;
  final VoidCallback onFilter;

  const TitleWithSearchAndFilter({
    required this.onSearch,
    required this.onFilter,
    this.hasBackButton = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40.0, left: 10.0, right: 10.0, bottom: 20.0),
      child: Row(
        children: [
          if (hasBackButton)
            IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.blueGrey, size: 25.0),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          if (hasBackButton) const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: onSearch,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                hintText: 'Search...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                suffixIcon: const Icon(Icons.search, color: Colors.blueGrey),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: Colors.blueGrey, size: 25.0),
            onPressed: onFilter,
          ),
        ],
      ),
    );
  }
}
