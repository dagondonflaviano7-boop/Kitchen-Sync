import 'package:flutter/material.dart';

class ProductThumbnail extends StatelessWidget {
  final String? imageUrl;
  final String productName;
  final double size;

  const ProductThumbnail({
    super.key,
    required this.imageUrl,
    required this.productName,
    this.size = 64,
  });

  Widget _placeholder(
    BuildContext context,
  ) {
    return Semantics(
      label: 'Product image is unavailable for $productName',
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        color: const Color(0xFFE8F1EC),
        child: Icon(
          Icons.inventory_2_outlined,
          size: size * 0.44,
          color: const Color(0xFF2E6B4F),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedUrl = imageUrl?.trim() ?? '';

    final Widget picture = normalizedUrl.trim().isEmpty
        ? _placeholder(context)
        : Image.network(
            normalizedUrl,
            semanticLabel: productName,
            width: size,
            height: size,
            fit: BoxFit.cover,
            loadingBuilder: (
              BuildContext context,
              Widget child,
              ImageChunkEvent? progress,
            ) {
              if (progress == null) {
                return child;
              }

              final int? total = progress.expectedTotalBytes;

              return SizedBox.square(
                dimension: size,
                child: Center(
                  child: SizedBox.square(
                    dimension: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: total == null
                          ? null
                          : progress.cumulativeBytesLoaded / total,
                    ),
                  ),
                ),
              );
            },
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return _placeholder(context);
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox.square(
        dimension: size,
        child: picture,
      ),
    );
  }
}
