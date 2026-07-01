import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({
    super.key,
    this.titleColor = AppColors.title,
    this.subtitleColor = AppColors.primary,
  });

  final Color titleColor;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const Icon(
            Icons.live_tv_rounded,
            size: 52,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 24),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Smart Ads',
                style: TextStyle(
                  color: titleColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'TV PLATFORM',
                style: TextStyle(
                  color: subtitleColor,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.8,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
