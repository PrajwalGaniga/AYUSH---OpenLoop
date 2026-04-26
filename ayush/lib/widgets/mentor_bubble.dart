import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../models/mentor_type.dart';

class MentorBubble extends StatefulWidget {
  final MentorType mentor;
  final String message;

  const MentorBubble({
    super.key,
    required this.mentor,
    required this.message,
  });

  @override
  State<MentorBubble> createState() => _MentorBubbleState();
}

class _MentorBubbleState extends State<MentorBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _replayLottie() {
    _controller.reset();
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey<String>(widget.message),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: widget.mentor.accentColor.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: _replayLottie,
              child: SizedBox(
                width: 48,
                height: 48,
                child: Lottie.asset(
                  widget.mentor.assetPath,
                  controller: _controller,
                  onLoaded: (composition) {
                    _controller.duration = composition.duration;
                    _controller.forward();
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.mentor.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: widget.mentor.accentColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
