import 'package:flutter/material.dart';

class BrandLogo extends StatelessWidget {
  const BrandLogo({this.size = 56, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: size * 0.25,
            left: size * 0.22,
            right: size * 0.22,
            child: _Line(width: size, color: scheme.onPrimary),
          ),
          Positioned(
            top: size * 0.43,
            left: size * 0.22,
            right: size * 0.22,
            child: _Line(width: size, color: scheme.onPrimary),
          ),
          Positioned(
            top: size * 0.61,
            left: size * 0.22,
            right: size * 0.38,
            child: _Line(width: size, color: scheme.onPrimary),
          ),
          Positioned(
            right: size * 0.16,
            bottom: size * 0.15,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                borderRadius: BorderRadius.circular(size),
              ),
              child: Icon(
                Icons.check,
                size: size * 0.18,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: width * 0.065,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(width),
      ),
    );
  }
}
