import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/r2_image_service.dart';

class R2ImageWidget extends ConsumerStatefulWidget {
  final String? imageKey;
  final double height;
  final double width;
  final BoxFit fit;
  final double borderRadius;

  const R2ImageWidget({
    super.key,
    required this.imageKey,
    this.height = 150,
    this.width = double.infinity,
    this.fit = BoxFit.cover,
    this.borderRadius = 16.0,
  });

  @override
  ConsumerState<R2ImageWidget> createState() => _R2ImageWidgetState();
}

class _R2ImageWidgetState extends ConsumerState<R2ImageWidget> {
  bool _hasRetried = false;

  @override
  Widget build(BuildContext context) {
    if (widget.imageKey == null || widget.imageKey!.isEmpty) {
      return _buildPlaceholder();
    }

    return ref
        .watch(eventImageProvider(widget.imageKey!))
        .when(
          data: (signedUrl) {
            if (signedUrl == null) return _buildPlaceholder();

            return ClipRRect(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              child: Image.network(
                signedUrl,
                height: widget.height,
                width: widget.width,
                fit: widget.fit,
                errorBuilder: (_, __, ___) {
                  if (!_hasRetried) {
                    _hasRetried = true;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      ref
                          .read(r2ImageServiceProvider)
                          .invalidateCache(widget.imageKey!);
                      ref.refresh(eventImageProvider(widget.imageKey!));
                    });
                    return _buildLoading();
                  }
                  return _buildPlaceholder();
                },
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    child: child,
                  );
                },
              ),
            );
          },
          loading: () => _buildLoading(),
          error: (_, __) => _buildPlaceholder(),
        );
  }

  Widget _buildLoading() {
    return TweenAnimationBuilder(
      tween: Tween<double>(begin: 0.5, end: 1.0),
      duration: const Duration(milliseconds: 1000),
      builder: (context, val, child) {
        return Opacity(
          opacity: val,
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: const Color(0xFF0A0A0F),
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
      onEnd: () {},
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: const Color(0xFF1B1B26)),
      ),
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          color: Color(0xFF7C3AED),
          size: 40,
        ),
      ),
    );
  }
}
