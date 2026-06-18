import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/animations/loading.json',
      delegates: LottieDelegates(
        values: [
          ValueDelegate.colorFilter(
            const ['**'],
            value: const ColorFilter.mode(Color(0xFF2563EB), BlendMode.srcATop),
          ),
        ],
      ),
    );
  }
}
