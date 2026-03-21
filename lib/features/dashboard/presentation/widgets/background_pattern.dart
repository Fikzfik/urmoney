import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';

class BackgroundPattern extends StatelessWidget {
  const BackgroundPattern({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Top right blob
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.05),
            ),
          ),
        ),
        // Middle left blob
        Positioned(
          top: 300,
          left: -150,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardOrange.colors.first.withOpacity(0.05),
            ),
          ),
        ),
        // Bottom right blob
        Positioned(
          bottom: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.cardPurple.colors.first.withOpacity(0.05),
            ),
          ),
        ),
      ],
    );
  }
}
