import 'package:flutter/material.dart';

/// Avatar/capa do perfil: evita `Image.network('')` e força rebuild quando a URL muda.
class ProfileMediaImage extends StatelessWidget {
  const ProfileMediaImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.error,
  });

  final String url;
  final double width;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? error;

  @override
  Widget build(BuildContext context) {
    final resolved = url.trim();
    Widget child;
    if (resolved.isEmpty) {
      child = error ?? const SizedBox.shrink();
    } else {
      child = Image.network(
        resolved,
        key: ValueKey<String>(resolved),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, _, _) => error ?? const SizedBox.shrink(),
        loadingBuilder: (context, imageChild, progress) {
          if (progress == null) return imageChild;
          return placeholder ?? const SizedBox.shrink();
        },
      );
    }

    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return SizedBox(width: width, height: height, child: child);
  }
}
