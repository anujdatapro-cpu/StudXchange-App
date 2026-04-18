import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class TopBanner extends StatelessWidget {
  const TopBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF0A84FF).withAlpha(51),
            const Color(0xFF1E3A8A).withAlpha(51),
            const Color(0xFF0A84FF).withAlpha(26),
          ],
        ),
        border: Border.all(
          color: colors.accent.withAlpha(102),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.accent.withAlpha(51),
            blurRadius: 22,
            spreadRadius: 2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Discover Deals 🔥',
            style: TextStyle(
              color: colors.primaryText,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Best finds from VIT Pune',
            style: TextStyle(
              color: colors.secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
