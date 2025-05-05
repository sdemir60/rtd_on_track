import 'package:flutter/material.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final Color backgroundColor;
  final double opacity;
  final double indicatorSize;
  final Color indicatorColor;
  final double elevation;

  const LoadingOverlay({
    Key? key,
    required this.isLoading,
    required this.child,
    this.backgroundColor = Colors.black,
    this.opacity = 0.5,
    this.indicatorSize = 40.0,
    this.indicatorColor = Colors.blue,
    this.elevation = 4.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: _buildLoadingOverlay(),
          ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: backgroundColor.withOpacity(opacity),
            ),
          ),
          Center(
            child: Card(
              elevation: elevation,
              shape: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: SizedBox(
                  height: indicatorSize,
                  width: indicatorSize,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
