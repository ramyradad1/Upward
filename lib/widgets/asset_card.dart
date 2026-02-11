import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/asset_model.dart';
import '../theme/app_theme.dart';
import 'hover_scale.dart';

class AssetCard extends StatefulWidget {
  final AssetModel asset;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const AssetCard({
    super.key,
    required this.asset,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<AssetCard> createState() => _AssetCardState();
}

class _AssetCardState extends State<AssetCard>
    with SingleTickerProviderStateMixin {

  Color _statusColor(AssetStatus status) {
    switch (status) {
      case AssetStatus.inStock:
        return AppTheme.accentColor;
      case AssetStatus.assigned:
        return AppTheme.primaryColor;
      case AssetStatus.repair:
        return AppTheme.accentWarm;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(AssetStatus status) {
    switch (status) {
      case AssetStatus.inStock:
        return 'In Stock';
      case AssetStatus.assigned:
        return 'Assigned';
      case AssetStatus.repair:
        return 'Repair';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final statusColor = _statusColor(widget.asset.status);

    return RepaintBoundary(
      child: HoverScale(
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.borderColor(context)),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : statusColor.withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Image
                  Hero(
                    tag: widget.asset.id,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 72,
                          minHeight: 72,
                          maxWidth: 150,
                          maxHeight: 150,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppTheme.inputFill(context),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: widget.asset.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.asset.imageUrl,
                                  fit: BoxFit.cover, // Ensures the image covers the available space
                                  memCacheWidth: 400, // Increased cache width since image can be larger
                                placeholder: (context, url) => Container(
                                    width: 72, 
                                    height: 72, // Default size while loading
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.inputFill(context),
                                          AppTheme.surfaceColor(context),
                                        ],
                                      ),
                                    ),
                                    child: Icon(Icons.devices_rounded,
                                        color: AppTheme.iconColor(context),
                                        size: 28),
                                  ),
                                errorWidget: (context, url, error) => Container(
                                    width: 72,
                                    height: 72,
                                    alignment: Alignment.center,
                                    child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: AppTheme.iconColor(context),
                                        size: 28),
                                  ),
                                )
                              : SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: Icon(Icons.devices_rounded,
                                      color: AppTheme.iconColor(context), size: 28),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.asset.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded,
                                size: 14,
                                color: AppTheme.textHint(context)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.asset.serialNumber,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary(context),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        if (widget.asset.assignedTo != null) ...[
                          Row(
                            children: [
                              Icon(Icons.person_outline_rounded,
                                  size: 14, color: AppTheme.primaryColor),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.asset.assignedTo!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Status badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: isDark ? 0.15 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      _statusLabel(widget.asset.status),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
          ),
        ),
      ),
    );
  }
}
