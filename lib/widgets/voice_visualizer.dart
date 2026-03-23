import 'dart:math';
import 'package:flutter/material.dart';

class VoiceVisualizer extends StatefulWidget {
  const VoiceVisualizer({Key? key}) : super(key: key);

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildBar(int index) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Random height variation synchronized with controller
        final height = 10.0 + _random.nextDouble() * 20.0 * _controller.value;
        return Container(
          width: 4,
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 30,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(5, (index) => _buildBar(index)),
      ),
    );
  }
}
