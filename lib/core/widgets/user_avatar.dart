import 'package:flutter/material.dart';
import 'package:pyrosfitmovil/core/services/storage_service.dart';
import 'package:pyrosfitmovil/theme/app_theme.dart';

class UserAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? storageKey;
  final String? initial;
  final double size;
  final double borderRadius;
  final BoxShape shape;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;

  const UserAvatar({
    super.key,
    this.imageUrl,
    this.storageKey,
    this.initial,
    this.size = 40,
    this.borderRadius = 12,
    this.shape = BoxShape.circle,
    this.onTap,
    this.showBorder = true,
    this.borderColor,
  });

  String get _effectiveInitial {
    if (initial != null && initial!.trim().isNotEmpty) {
      return initial!.trim().substring(0, 1).toUpperCase();
    }
    return 'U';
  }

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = StorageService.getServeUrl(storageKey ?? imageUrl);
    final isCircle = shape == BoxShape.circle;
    final rBorder = isCircle ? BorderRadius.circular(size / 2) : BorderRadius.circular(borderRadius);

    Widget avatarContent;

    if (effectiveUrl.isNotEmpty) {
      avatarContent = Image.network(
        effectiveUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildFallback(isPlaceholder: true);
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildFallback();
        },
      );
    } else {
      avatarContent = _buildFallback();
    }

    Widget container = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: shape,
        borderRadius: isCircle ? null : rBorder,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppTheme.border,
                width: 1.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: rBorder,
        child: avatarContent,
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: container,
      );
    }

    return container;
  }

  Widget _buildFallback({bool isPlaceholder = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: AppTheme.fireGradient,
        shape: shape,
      ),
      alignment: Alignment.center,
      child: isPlaceholder
          ? SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            )
          : Text(
              _effectiveInitial,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: size * 0.48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.0,
              ),
            ),
    );
  }
}
