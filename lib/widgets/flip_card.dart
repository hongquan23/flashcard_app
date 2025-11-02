// widgets/flip_card.dart - FIX KHÔNG NGƯỢC CHỮ + HÌNH AN TOÀN
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class FlipCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? imagePath;
  const FlipCard({
    super.key,
    required this.frontText,
    required this.backText,
    this.imagePath,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
  }

  void _toggle() {
    if (isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => isFront = !isFront);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null && File(widget.imagePath!).existsSync();

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final isUnder = angle > (pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isUnder ? Colors.green[600] : Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
                ],
              ),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(isUnder ? pi : 0), // Giữ chữ & ảnh đúng chiều
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildCardContent(isUnder, hasImage),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(bool isUnder, bool hasImage) {
    if (!isUnder && hasImage) {
      // Mặt trước có ảnh
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(
            Icons.broken_image,
            size: 60,
            color: Colors.white70,
          ),
        ),
      );
    } else {
      // Mặt sau hoặc mặt trước không có ảnh
      return Center(
        child: Text(
          isUnder ? widget.backText : widget.frontText,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
