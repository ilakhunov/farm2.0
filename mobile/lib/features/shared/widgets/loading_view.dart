import 'package:flutter/material.dart';

import '../../../core/widgets/skeleton_loader.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class ProductsLoadingView extends StatelessWidget {
  const ProductsLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) => const ProductCardSkeleton(),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemCount: 5,
    );
  }
}
