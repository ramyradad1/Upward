import 'dart:io';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_theme.dart';

class UploadCard extends StatelessWidget {
  final String label;
  final String? subLabel;
  final IconData? icon;
  final bool isMain;
  final XFile? imageFile;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const UploadCard({
    super.key,
    required this.label,
    this.subLabel,
    this.icon,
    this.isMain = false,
    this.imageFile,
    this.imageUrl,
    required this.onTap,
    this.onRemove,
  });

  bool get _hasImage => imageFile != null || (imageUrl != null && imageUrl!.isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppTheme.textSecondary(context),
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: AppTheme.animNormal,
            curve: Curves.easeOutCubic,
            height: isMain ? 200 : 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _hasImage
                  ? Colors.transparent
                  : AppTheme.glassColor(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _hasImage
                    ? AppTheme.primaryColor.withValues(alpha: 0.3)
                    : AppTheme.borderColor(context),
                width: _hasImage ? 2 : 1.5,
              ),
              boxShadow: _hasImage
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: _hasImage ? _buildImageView(context) : _buildEmptyState(context, isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon ?? Icons.add_photo_alternate_rounded,
              color: AppTheme.primaryColor.withValues(alpha: 0.8),
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            subLabel ?? 'Tap to upload image',
            style: TextStyle(
              color: AppTheme.textPrimary(context),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'JPG, PNG up to 10MB',
            style: TextStyle(
              color: AppTheme.textHint(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageView(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (imageFile != null)
          kIsWeb
              ? Image.network(imageFile!.path, fit: BoxFit.cover)
              : Image.file(File(imageFile!.path), fit: BoxFit.cover)
        else if (imageUrl != null && imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: imageUrl!,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: AppTheme.inputFill(context),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              color: AppTheme.inputFill(context),
              child: Icon(Icons.image_not_supported_outlined,
                  color: AppTheme.iconColor(context), size: 32),
            ),
          ),
        // Edit overlay
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentWarm.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
      ],
    );
  }
}

