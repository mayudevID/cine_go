import 'package:flutter/material.dart';

import 'app_shimmer.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
    child: AppShimmer(child: AppShimmerBox(width: 144, height: 18)),
  );
}
