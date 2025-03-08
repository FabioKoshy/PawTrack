import 'package:flutter/material.dart';

class SquareButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const SquareButton({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: MediaQuery.of(context).size.width * 0.25,
            height: MediaQuery.of(context).size.width * 0.25,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              border: isSelected ? Border.all(color: Colors.pink.shade800, width: 3) : null,
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 40),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}