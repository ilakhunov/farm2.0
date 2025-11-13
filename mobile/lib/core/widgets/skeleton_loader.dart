import 'package:flutter/material.dart';

class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const SkeletonLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 1500),
        builder: (context, value, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey[300]!,
                  Colors.grey[200]!,
                  Colors.grey[300]!,
                ],
                stops: [value - 0.3, value, value + 0.3],
              ),
              borderRadius: borderRadius ?? BorderRadius.circular(8),
            ),
          );
        },
        onEnd: () {},
      ),
    );
  }
}

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: SkeletonLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
        title: SkeletonLoader(height: 16),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            SkeletonLoader(height: 12),
            SizedBox(height: 4),
            SkeletonLoader(height: 12, width: 150),
          ],
        ),
      ),
    );
  }
}

