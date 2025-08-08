import 'package:flutter/material.dart';

class CircleHoleClipper extends CustomClipper<Path> {
  final Offset center;
  final double radius;

  CircleHoleClipper({required this.center, required this.radius});

  @override
  Path getClip(Size size) {
    final path = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    path.addOval(Rect.fromCircle(center: center, radius: radius));
    return Path.combine(
      PathOperation.difference,
      path,
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}
