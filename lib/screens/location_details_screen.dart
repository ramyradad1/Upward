import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../models/location_model.dart';
import '../models/asset_model.dart';
import '../services/asset_service.dart';
import '../theme/app_theme.dart';
import 'asset_details_screen.dart';

class LocationDetailsScreen extends StatefulWidget {
  final LocationModel location;

  const LocationDetailsScreen({super.key, required this.location});

  @override
  State<LocationDetailsScreen> createState() => _LocationDetailsScreenState();
}

class _LocationDetailsScreenState extends State<LocationDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Stream<List<AssetModel>> _assetsStream;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _animController.forward();
    _assetsStream = AssetService.getAssetsByLocationStream(widget.location.id);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _typeColor(LocationType type) {
    switch (type) {
      case LocationType.branch:
        return AppTheme.primaryColor;
      case LocationType.room:
        return AppTheme.accentColor;
      case LocationType.warehouse:
        return const Color(0xFFFF9800);
      case LocationType.rack:
        return const Color(0xFF9C27B0);
    }
  }

  IconData _typeIcon(LocationType type) {
    switch (type) {
      case LocationType.branch:
        return Icons.business_rounded;
      case LocationType.room:
        return Icons.meeting_room_rounded;
      case LocationType.warehouse:
        return Icons.warehouse_rounded;
      case LocationType.rack:
        return Icons.dns_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final headerAnim = AppTheme.staggerAnimation(_animController, 0);
    final listAnim = AppTheme.staggerAnimation(_animController, 1);
    final color = _typeColor(widget.location.type);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(headerAnim),
                  child: FadeTransition(
                    opacity: headerAnim,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 24, 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.glassColor(context),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppTheme.borderColor(context)),
                                ),
                                child: IconButton(
                                  onPressed: () {
                                    if (context.canPop()) {
                                      context.pop();
                                    } else {
                                      context.go('/locations');
                                    }
                                  },
                                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary(context), size: 18),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(_typeIcon(widget.location.type), color: color, size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          LocationModel.typeToString(widget.location.type),
                                          style: TextStyle(
                                            color: color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      widget.location.name,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.textPrimary(context),
                                        height: 1.2,
                                      ),
                                    ),
                                    if (widget.location.address != null && widget.location.address!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary(context)),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              widget.location.address!,
                                              style: TextStyle(
                                                color: AppTheme.textSecondary(context),
                                                fontSize: 13,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Assets List
                Expanded(
                  child: SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(listAnim),
                    child: FadeTransition(
                      opacity: listAnim,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.cardColor(context),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor(context),
                              blurRadius: 20,
                              offset: const Offset(0, -5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: StreamBuilder<List<AssetModel>>(
                            stream: _assetsStream,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                              }

                              final assets = snapshot.data ?? [];

                              if (assets.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No Assets Here',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Move assets to this location via Edit Asset',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppTheme.textSecondary(context),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Assigned Assets',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary(context),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '${assets.length} items',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: ListView.separated(
                                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                                      itemCount: assets.length,
                                      separatorBuilder: (_, index) => const SizedBox(height: 12),
                                      itemBuilder: (context, index) {
                                        final asset = assets[index];
                                        return _buildAssetCard(context, asset);
                                      },
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(BuildContext context, AssetModel asset) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context).withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              AppTheme.slideRoute(AssetDetailsScreen(asset: asset)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.inputFill(context),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor(context)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: asset.imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: asset.imageUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                            errorWidget: (_, __, ___) => Icon(Icons.broken_image_rounded, color: AppTheme.textHint(context)),
                          )
                        : Icon(Icons.image_not_supported_rounded, color: AppTheme.textHint(context)),
                  ),
                ),
                const SizedBox(width: 16),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        asset.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.textPrimary(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        asset.serialNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary(context),
                          fontFamily: 'Monospace',
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              asset.category,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppTheme.textHint(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
