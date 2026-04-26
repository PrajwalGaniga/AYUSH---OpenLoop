import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart';
import '../models/mentor_type.dart';
import '../services/mentor_service.dart';

class MentorWidget extends StatefulWidget {
  final MentorType mentor;
  final String message;
  final bool dismissible;
  final VoidCallback? onDismiss;
  final bool animate;

  const MentorWidget({
    super.key,
    required this.mentor,
    required this.message,
    this.dismissible = true,
    this.onDismiss,
    this.animate = true,
  });

  @override
  State<MentorWidget> createState() => _MentorWidgetState();
}

class _MentorWidgetState extends State<MentorWidget> with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _replayLottie() {
    _controller.reset();
    _controller.forward();
  }

  void _handleLongPress() async {
    if (kDebugMode) {
      // Just some common screen keys used in the app
      await MentorService.resetFirstVisit('home_ojas_alert');
      await MentorService.resetFirstVisit('health_radar');
      await MentorService.resetFirstVisit('prakriti_screen');
      await MentorService.resetFirstVisit('log_screen');
      await MentorService.resetFirstVisit('ojas_screen');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('First visit flags reset.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isLoading = widget.message.isEmpty;
    final ThemeData theme = Theme.of(context);
    final Color bgColor = theme.cardColor;
    final Color textColor = theme.textTheme.bodyMedium?.color ?? Colors.grey.shade800;

    return Semantics(
      label: "${widget.mentor.displayName} says: ${isLoading ? 'Loading message' : widget.message}",
      button: false,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.2),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: Container(
          key: ValueKey<String>(widget.message),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.mentor.accentColor.withOpacity(0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.mentor.accentColor.withOpacity(0.10),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LEFT: Lottie animation
              GestureDetector(
                onTap: _replayLottie,
                onLongPress: kDebugMode ? _handleLongPress : null,
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Lottie.asset(
                    widget.mentor.assetPath,
                    controller: _controller,
                    onLoaded: (composition) {
                      _controller.duration = composition.duration;
                      if (widget.animate) {
                        _controller.forward();
                      } else {
                        _controller.value = 0; // static first frame
                      }
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: widget.mentor.accentColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          widget.mentor.displayName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: widget.mentor.accentColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // RIGHT: Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.mentor.displayName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: widget.mentor.accentColor,
                          ),
                        ),
                        if (widget.dismissible)
                          GestureDetector(
                            onTap: widget.onDismiss,
                            child: Icon(
                              Icons.close,
                              size: 16,
                              color: widget.mentor.accentColor.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (isLoading)
                      _buildShimmer(context)
                    else
                      Text(
                        widget.message,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor,
                          height: 1.5,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                Colors.grey.withOpacity(0.2),
                Colors.grey.withOpacity(0.4),
                Colors.grey.withOpacity(0.2),
              ],
              stops: const [0.1, 0.5, 0.9],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
            ).createShader(bounds);
          },
          child: Container(
            height: 14,
            width: MediaQuery.of(context).size.width * 0.6,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});
  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (slidePercent * 2 - 1), 0.0, 0.0);
  }
}
