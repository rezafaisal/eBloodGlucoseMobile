import 'package:blur/blur.dart';
import 'package:flutter/material.dart';

class RoundedImageCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final VoidCallback? onTap;

  const RoundedImageCard({super.key, required this.imageUrl, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12.0), // Adjust the radius as needed
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: Text(
                title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ).frosted(
                blur: 3,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
              ),
            )
          ],
        ),
      ),
    );
  }
}
