import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double progress;
  final String message;

  const LoadingIndicator({
    super.key,
    required this.progress,
    this.message = 'Processing...',
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(message),
      ],
    );
  }
}
