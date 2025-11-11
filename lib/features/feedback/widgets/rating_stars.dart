import 'package:flutter/material.dart';

class RatingStars extends StatelessWidget {
  final int value; // 0..5
  final ValueChanged<int> onChanged;
  final double size;
  const RatingStars({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i < value;
        return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => onChanged(i + 1),
          icon: Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            color: filled ? Colors.amber : Colors.grey.shade400,
            size: size,
          ),
        );
      }),
    );
  }
}
