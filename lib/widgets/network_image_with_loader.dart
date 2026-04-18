import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NetworkImageWithLoader extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final double? iconSize;
  final Color? backgroundColor;

  const NetworkImageWithLoader({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.iconSize,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        color: backgroundColor ?? colors.card,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: imageUrl != null && imageUrl!.isNotEmpty
            ? Image.network(
                imageUrl!,
                fit: fit,
                width: width,
                height: height,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      color: colors.accent,
                      strokeWidth: 2,
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Icon(
                      Icons.image,
                      color: colors.secondaryText,
                      size: iconSize ?? 48,
                    ),
                  );
                },
              )
            : Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  color: colors.secondaryText,
                  size: iconSize ?? 48,
                ),
              ),
      ),
    );
  }
}
