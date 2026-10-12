import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 20,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(5, (index) {
        final value = index + 1;
        final icon = Icon(
          value <= rating ? Icons.star_rounded : Icons.star_border_rounded,
          size: size,
          color: const Color(0xFFF59E0B),
        );
        if (onChanged == null) {
          return icon;
        }
        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => onChanged!(value),
          child: Padding(
            padding: const EdgeInsets.all(2),
            child: icon,
          ),
        );
      }),
    );
  }
}
