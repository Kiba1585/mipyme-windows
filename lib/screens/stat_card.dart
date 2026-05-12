import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? Colors.grey.shade800 : (color?.withOpacity(0.1) ?? Colors.white);
    final textColor = isDark ? Colors.white : Colors.black87;
    final iconColor = color ?? (isDark ? Colors.white : Colors.blue);

    return Expanded(
      child: Card(
        color: cardColor,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Icon(icon, size: 30, color: iconColor),
                const SizedBox(height: 8),
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: iconColor)),
                Text(title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}