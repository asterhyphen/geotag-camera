import 'package:flutter/material.dart';

class AspectRatioOption {
  final String label;
  final String sub;
  final double ratio;
  final IconData icon;

  const AspectRatioOption({
    required this.label,
    required this.sub,
    required this.ratio,
    required this.icon,
  });
}

const List<AspectRatioOption> kAspectRatioOptions = [
  AspectRatioOption(
    label: '3:4',
    sub: 'Portrait',
    ratio: 3 / 4,
    icon: Icons.crop_portrait_rounded,
  ),
  AspectRatioOption(
    label: '1:1',
    sub: 'Square',
    ratio: 1.0,
    icon: Icons.crop_square_rounded,
  ),
  AspectRatioOption(
    label: '9:16',
    sub: 'Full',
    ratio: 9 / 16,
    icon: Icons.stay_current_portrait_rounded,
  ),
  AspectRatioOption(
    label: '4:3',
    sub: 'Classic',
    ratio: 4 / 3,
    icon: Icons.crop_landscape_rounded,
  ),
  AspectRatioOption(
    label: '16:9',
    sub: 'Cinema',
    ratio: 16 / 9,
    icon: Icons.crop_16_9_rounded,
  ),
];

String getAspectRatioLabel(double ratio) {
  if ((ratio - 1.0).abs() < 0.05) return '1:1';
  if ((ratio - (3 / 4)).abs() < 0.05) return '3:4';
  if ((ratio - (9 / 16)).abs() < 0.05) return '9:16';
  if ((ratio - (4 / 3)).abs() < 0.05) return '4:3';
  if ((ratio - (16 / 9)).abs() < 0.05) return '16:9';
  return '3:4';
}
