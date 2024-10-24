import 'package:flutter/material.dart';
import 'package:space_sculpt_mobile_app/routes.dart';

class FurnitureCard extends StatelessWidget {
  final Map<dynamic, dynamic> data;

  const FurnitureCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double price = 0.0;
    double averageRating = 0.0;
    int ratingCount = 0;

    // Parse price
    try {
      price = double.parse(data['price'].toString());
    } catch (e) {
      print('Error parsing price: $e');
    }

    // Ensure discount is valid, default to 0 if null
    var discount = data['discount'] ?? 0;

    // Parse ratings if available
    if (data['ratings'] != null && data['ratings'] is List) {
      List ratingsList = data['ratings'];
      ratingCount = ratingsList.length;
      double totalRatings = 0.0;

      for (var rating in ratingsList) {
        if (rating['rating'] != null) {
          totalRatings += double.parse(rating['rating'].toString());
        }
      }

      if (ratingCount > 0) {
        averageRating = totalRatings / ratingCount;
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          Routes.customerFurnitureDetails,
          arguments: data['id'],
        );
      },
      child: SizedBox(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Display image
              SizedBox(
                height: 150,
                child: data['mainImage'] != null
                    ? Image.network(
                  data['mainImage'],
                  height: 140,
                  fit: BoxFit.contain,
                )
                    : const Center(child: Text('No Image')),
              ),
              const SizedBox(height: 5),
              // Display furniture name
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  data['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 16,
                    fontFamily: 'Poppins_Bold',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              // Display price and discount
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Text(
                      'RM ${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontFamily: 'Poppins_Medium',
                        color: Colors.black,
                      ),
                    ),
                    if ((int.parse(discount.toString())) > 0) ...[
                      const SizedBox(width: 8.0),
                      Text(
                        '- ${discount.toString()}%',
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                          fontFamily: 'Poppins_Medium',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 5),
              // Display average rating and count
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 15,
                        );
                      }),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '($ratingCount)',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Poppins_Medium',
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}