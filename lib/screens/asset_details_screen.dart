import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/asset_model.dart';
import '../models/handover_model.dart';
import '../models/maintenance_model.dart';
import '../services/encryption_service.dart';
import '../services/handover_service.dart';
import '../services/maintenance_service.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  final String tag;

  const FullScreenImage({super.key, required this.imageUrl, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            boundaryMargin: const EdgeInsets.all(20),
            minScale: 0.5,
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const CircularProgressIndicator(),
              errorWidget: (context, url, error) => const Icon(Icons.broken_image, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class AssetDetailsScreen extends StatefulWidget {
  final AssetModel asset;

  const AssetDetailsScreen({super.key, required this.asset});

  @override
  State<AssetDetailsScreen> createState() => _AssetDetailsScreenState();
}

class _AssetDetailsScreenState extends State<AssetDetailsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    
    // Staggered Animations
    final headerAnim = AppTheme.staggerAnimation(_controller, 0);
    final statusAnim = AppTheme.staggerAnimation(_controller, 1);
    final assignAnim = AppTheme.staggerAnimation(_controller, 2);
    final accessAnim = AppTheme.staggerAnimation(_controller, 3);
    final specsAnim = AppTheme.staggerAnimation(_controller, 4);
    final imagesAnim = AppTheme.staggerAnimation(_controller, 5);

    return Scaffold(
      backgroundColor: isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(headerAnim),
                  child: FadeTransition(opacity: headerAnim, child: _buildHeader(context)),
                ),
                const SizedBox(height: 32),
                
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(statusAnim),
                  child: FadeTransition(opacity: statusAnim, child: _buildStatusSection(context)),
                ),
                const SizedBox(height: 24),
                
                if (widget.asset.assignedTo != null) ...[
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(assignAnim),
                    child: FadeTransition(opacity: assignAnim, child: _buildAssignmentSection(context)),
                  ),
                  const SizedBox(height: 24),
                ],
                
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(accessAnim),
                  child: FadeTransition(opacity: accessAnim, child: _buildAccessoriesSection(context)),
                ),
                const SizedBox(height: 24),

                // Specs & Network Section (Phase 1)
                if (_hasSpecsOrNetwork()) ...[
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(specsAnim),
                    child: FadeTransition(opacity: specsAnim, child: _buildSpecsSection(context)),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(height: 24),
                ],

                // Configuration & Security Section (Phase 2)
                if (widget.asset.configFileUrl != null || widget.asset.secureCredentials != null) ...[
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(specsAnim),
                    child: FadeTransition(opacity: specsAnim, child: _buildConfigSection(context)),
                  ),
                  const SizedBox(height: 24),
                ],

                // Notes Section
                if (widget.asset.notes != null && widget.asset.notes!.isNotEmpty) ...[
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(specsAnim),
                    child: FadeTransition(opacity: specsAnim, child: _buildNotesSection(context)),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // QR Code Section

                // Financial & Depreciation Section (Phase 6)
                if (widget.asset.purchasePrice != null || widget.asset.warrantyExpiry != null) ...[
                  SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(specsAnim),
                    child: FadeTransition(opacity: specsAnim, child: _buildDepreciationSection(context)),
                  ),
                  const SizedBox(height: 24),
                ],

                // Maintenance History Section (Phase 6)
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(imagesAnim),
                  child: FadeTransition(opacity: imagesAnim, child: _buildMaintenanceSection(context)),
                ),
                const SizedBox(height: 24),
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(imagesAnim),
                  child: FadeTransition(
                    opacity: imagesAnim,
                    child: _buildQrCodeSection(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Handover History Section
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(imagesAnim),
                  child: FadeTransition(
                    opacity: imagesAnim,
                    child: _buildHandoverHistorySection(context),
                  ),
                ),
                const SizedBox(height: 24),
                
                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(imagesAnim),
                  child: FadeTransition(
                    opacity: imagesAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gallery',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildMainImage(context),
                        if (widget.asset.imageUrls.length > 1) ...[
                          const SizedBox(height: 12),
                          _buildImageThumbnails(context),
                        ],
                        if (widget.asset.custodyImageUrl != null && widget.asset.custodyImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildCustodySection(context),
                        ],
                        if (widget.asset.idCardImageUrl != null && widget.asset.idCardImageUrl!.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildIdCardSection(context),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100), // Bottom padding for FAB
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _controller, curve: const Interval(0.6, 1.0, curve: Curves.elasticOut)),
        child: FloatingActionButton.extended(
          onPressed: () {
            context.push('/assets/edit', extra: widget.asset);
          },
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          highlightElevation: 8,
          icon: const Icon(Icons.edit_rounded, color: Colors.white),
          label: const Text(
            'Edit Asset',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: AppTheme.backgroundDark.withValues(
        alpha: 0.95,
      ), // Slight transparency
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/dashboard');
              }
            },
            color: Colors.white,
            tooltip: 'Back',
          ),
        ),
      ),
      title: const Text(
        'Asset Details',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
      ),
      centerTitle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.asset.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary(context).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: SelectableText( // Make serial copyable
                widget.asset.id.split('-').first.toUpperCase(),
                style: TextStyle(
                  color: AppTheme.textSecondary(context),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Monospace',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SelectableText(
          widget.asset.name,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppTheme.textPrimary(context),
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppTheme.textSecondary(context).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.qr_code_2_rounded, size: 20, color: AppTheme.textSecondary(context)),
            ),
            const SizedBox(width: 10),
            SelectableText(
              widget.asset.serialNumber,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w500,
                fontFamily: 'Monospace',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusSection(BuildContext context) {
    Color color;
    String label;
    IconData icon;
    String description;

    switch (widget.asset.status) {
      case AssetStatus.inStock:
        color = AppTheme.accentColor;
        label = 'In Stock';
        icon = Icons.check_circle_rounded;
        description = 'Available for assignment';
        break;
      case AssetStatus.assigned:
        color = AppTheme.primaryColor;
        label = 'Assigned';
        icon = Icons.person_rounded;
        description = 'Currently in use';
        break;
      case AssetStatus.repair:
        color = AppTheme.accentWarm;
        label = 'Maintenance';
        icon = Icons.build_rounded;
        description = 'Under repair or broken';
        break;
      default:
        color = Colors.grey;
        label = 'Unknown';
        icon = Icons.help_rounded;
        description = 'Status not defined';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Status',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary(context),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: color.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentSection(BuildContext context) {
    return _SectionCard(
      title: 'Assigned To',
      icon: Icons.badge_rounded,
      child: Row(
        children: [
          Hero(
            tag: 'assignee_${widget.asset.id}',
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipOval(
                child: widget.asset.assignedToImage != null && widget.asset.assignedToImage!.isNotEmpty
                    ? CachedNetworkImage(imageUrl: widget.asset.assignedToImage!, fit: BoxFit.cover)
                    : Container(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: Icon(Icons.person_rounded, color: AppTheme.primaryColor, size: 28),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.asset.assignedTo ?? 'Unknown User',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary(context)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.textSecondary(context).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.asset.assignedToRole ?? 'Employee',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessoriesSection(BuildContext context) {
    if (widget.asset.bagType == null && widget.asset.headsetType == null && widget.asset.mouseType == null) {
      return const SizedBox.shrink();
    }

    return _SectionCard(
      title: 'Accessories',
      icon: Icons.devices_other_rounded,
      child: Column(
        children: [
          if (widget.asset.bagType != null && widget.asset.bagType!.isNotEmpty)
            _InfoRow(label: 'Bag', value: widget.asset.bagType!),
          
          if (widget.asset.headsetType != null && widget.asset.headsetType!.isNotEmpty)
            _InfoRow(label: 'Headset', value: widget.asset.headsetType!, subValue: widget.asset.headsetSerial),

          if (widget.asset.mouseType != null && widget.asset.mouseType!.isNotEmpty)
            _InfoRow(label: 'Mouse', value: widget.asset.mouseType!, subValue: widget.asset.mouseSerial),
        ],
      ),
    );
  }

  Widget _buildMainImage(BuildContext context) {
    return _InteractableImage(
      imageUrl: widget.asset.imageUrl,
      tag: widget.asset.id,
      height: 280,
      label: 'Device',
    );
  }

  Widget _buildIdCardSection(BuildContext context) {
    return _InteractableImage(
      imageUrl: widget.asset.idCardImageUrl!,
      tag: 'id_card_${widget.asset.id}',
      height: 200,
      label: 'ID Card',
    );
  }

  Widget _buildCustodySection(BuildContext context) {
    return _InteractableImage(
      imageUrl: widget.asset.custodyImageUrl!,
      tag: 'custody_${widget.asset.id}',
      height: 200,
      label: 'Custody Document',
    );
  }

  Widget _buildImageThumbnails(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: widget.asset.imageUrls.length,
        separatorBuilder: (_, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = widget.asset.imageUrls[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullScreenImage(imageUrl: url, tag: 'thumb_$index${widget.asset.id}'),
                ),
              );
            },
            child: Hero(
              tag: 'thumb_$index${widget.asset.id}',
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: url == widget.asset.imageUrl 
                        ? AppTheme.primaryColor 
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) =>
                        Container(color: AppTheme.inputFill(context)),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  bool _hasSpecsOrNetwork() {
    final a = widget.asset;
    return (a.locationName != null && a.locationName!.isNotEmpty) ||
        (a.cpu != null && a.cpu!.isNotEmpty) ||
        (a.ram != null && a.ram!.isNotEmpty) ||
        (a.storageSpec != null && a.storageSpec!.isNotEmpty) ||
        (a.hostname != null && a.hostname!.isNotEmpty) ||
        (a.ipAddress != null && a.ipAddress!.isNotEmpty) ||
        (a.macAddress != null && a.macAddress!.isNotEmpty);
  }

  Widget _buildSpecsSection(BuildContext context) {
    final a = widget.asset;
    return _SectionCard(
      title: 'Specs & Network',
      icon: Icons.memory_rounded,
      child: Column(
        children: [
          if (a.locationName != null && a.locationName!.isNotEmpty)
            _InfoRow(label: 'Location', value: a.locationName!),
          if (a.cpu != null && a.cpu!.isNotEmpty)
            _InfoRow(label: 'CPU', value: a.cpu!),
          if (a.ram != null && a.ram!.isNotEmpty)
            _InfoRow(label: 'RAM', value: a.ram!),
          if (a.storageSpec != null && a.storageSpec!.isNotEmpty)
            _InfoRow(label: 'Storage', value: a.storageSpec!),
          if (a.hostname != null && a.hostname!.isNotEmpty)
            _InfoRow(label: 'Hostname', value: a.hostname!),
          if (a.ipAddress != null && a.ipAddress!.isNotEmpty)
            _InfoRow(label: 'IP Address', value: a.ipAddress!),
          if (a.macAddress != null && a.macAddress!.isNotEmpty)
            _InfoRow(label: 'MAC Address', value: a.macAddress!),
        ],
      ),
    );
  }

  Widget _buildConfigSection(BuildContext context) {
    final a = widget.asset;
    return _SectionCard(
      title: 'Configuration & Security',
      icon: Icons.security_rounded,
      child: Column(
        children: [
          if (a.configFileUrl != null && a.configFileUrl!.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.inputFill(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.inputBorder(context)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.description_rounded, color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Config Backup',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          a.configFileName ?? 'config_backup.conf',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final uri = Uri.parse(a.configFileUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Could not launch file URL')),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.download_rounded, color: AppTheme.primaryColor),
                    tooltip: 'Download Config',
                  ),
                ],
              ),
            ),
          
          if (a.secureCredentials != null && a.secureCredentials!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   SizedBox(
                    width: 110,
                    child: Text(
                      'Credentials',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      _isPasswordVisible 
                          ? EncryptionService.decryptData(a.secureCredentials!) 
                          : 'â€¢â€¢â€¢â€¢â€¢â€¢â€¢â€¢',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppTheme.textPrimary(context),
                        fontWeight: FontWeight.w600,
                        fontFamily: _isPasswordVisible ? null : 'Monospace',
                        letterSpacing: _isPasswordVisible ? 0 : 2,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        _isPasswordVisible ? Icons.visibility_off_rounded : Icons.visibility_rounded, 
                        color: AppTheme.primaryColor,
                        size: 20,
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

  Widget _buildNotesSection(BuildContext context) {
    return _SectionCard(
      title: 'Notes / Wiki',
      icon: Icons.notes_rounded,
      child: SelectableText(
        widget.asset.notes!,
        style: TextStyle(
          fontSize: 14,
          color: AppTheme.textPrimary(context),
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildQrCodeSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QR Code',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: widget.asset.id,
                version: QrVersions.auto,
                size: 180,
                gapless: false,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Scan to view asset details',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverHistorySection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Handover History',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary(context),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<HandoverModel>>(
            future: HandoverService.getHandoverHistory(widget.asset.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final handovers = snapshot.data ?? [];

              if (handovers.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(Icons.history,
                            size: 40,
                            color: AppTheme.textHint(context)),
                        const SizedBox(height: 8),
                        Text(
                          'No handover records yet',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: handovers.map((handover) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz,
                              color: AppTheme.primaryColor, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${handover.fromUserName ?? 'System'} \u2192 ${handover.toUserName}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary(context),
                                ),
                              ),
                              if (handover.notes != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    handover.notes!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary(context),
                                    ),
                                  ),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(handover.createdAt),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textHint(context),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Phase 6: Financial & Depreciation Section
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildDepreciationSection(BuildContext context) {
    final a = widget.asset;
    final currencyLabel = a.currency ?? 'SAR';
    final priceStr = a.purchasePrice != null ? '${a.purchasePrice!.toStringAsFixed(0)} $currencyLabel' : null;
    final currentVal = a.currentValue;
    final currentStr = currentVal != null ? '${currentVal.toStringAsFixed(0)} $currencyLabel' : null;
    final depPercent = (a.purchasePrice != null && currentVal != null && a.purchasePrice! > 0)
        ? ((1 - currentVal / a.purchasePrice!) * 100).clamp(0, 100).toStringAsFixed(0)
        : null;

    return _SectionCard(
      title: 'Financial & Depreciation',
      icon: Icons.trending_down_rounded,
      child: Column(
        children: [
          if (priceStr != null) _InfoRow(label: 'Purchase Price', value: priceStr),
          if (a.purchaseDate != null)
            _InfoRow(label: 'Purchase Date', value: DateFormat('dd/MM/yyyy').format(a.purchaseDate!)),
          if (currentStr != null)
            _InfoRow(label: 'Current Value', value: currentStr),
          if (depPercent != null)
            _InfoRow(label: 'Depreciated', value: '$depPercent%'),
          if (a.usefulLifeYears != null)
            _InfoRow(label: 'Useful Life', value: '${a.usefulLifeYears} years'),
          if (a.salvageValue != null)
            _InfoRow(label: 'Salvage Value', value: '${a.salvageValue!.toStringAsFixed(0)} $currencyLabel'),
          if (a.warrantyExpiry != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: a.isWarrantyExpired
                        ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                        : const Color(0xFF10B981).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    a.isWarrantyExpired ? Icons.gpp_bad_rounded : Icons.verified_user_rounded,
                    size: 20,
                    color: a.isWarrantyExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.isWarrantyExpired ? 'Warranty Expired' : 'Warranty Active',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: a.isWarrantyExpired ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        ),
                      ),
                      Text(
                        a.isWarrantyExpired
                            ? 'Expired on ${DateFormat('dd/MM/yyyy').format(a.warrantyExpiry!)}'
                            : '${a.warrantyDaysRemaining} days remaining (${DateFormat('dd/MM/yyyy').format(a.warrantyExpiry!)})',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  // Phase 6: Maintenance History Section
  // â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Widget _buildMaintenanceSection(BuildContext context) {
    return _SectionCard(
      title: 'Maintenance History',
      icon: Icons.build_circle_rounded,
      child: FutureBuilder<List<MaintenanceLog>>(
        future: MaintenanceService.getLogsForAsset(widget.asset.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final logs = snapshot.data ?? [];
          if (logs.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No maintenance logs for this asset',
                  style: TextStyle(color: AppTheme.textHint(context), fontSize: 13),
                ),
              ),
            );
          }
          final recentLogs = logs.take(5).toList();
          return Column(
            children: recentLogs.map((log) {
              final statusColor = log.status == MaintenanceLogStatus.completed
                  ? const Color(0xFF10B981)
                  : log.status == MaintenanceLogStatus.partial
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFEF4444);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.inputFill(context),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.inputBorder(context)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(log.title, style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          )),
                          const SizedBox(height: 2),
                          Text(
                            '${log.performedBy} â€¢ ${DateFormat('dd/MM/yyyy').format(log.performedAt)}',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary(context)),
                          ),
                        ],
                      ),
                    ),
                    if (log.cost != null)
                      Text(
                        '${log.cost!.toStringAsFixed(0)} ${log.currency}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary(context),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _InteractableImage extends StatelessWidget {
  final String imageUrl;
  final String tag;
  final double height;
  final String label;

  const _InteractableImage({required this.imageUrl, required this.tag, required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (imageUrl.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(imageUrl: imageUrl, tag: tag),
            ),
          );
        }
      },
      child: Stack(
        children: [
          Hero(
            tag: tag,
            child: Container(
              height: height,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: AppTheme.inputFill(context),
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: AppTheme.inputFill(context),
                          child: const Icon(Icons.broken_image_rounded),
                        ),
                      )
                    : Container(
                        color: AppTheme.inputFill(context),
                        child: Icon(Icons.image_not_supported_rounded, size: 60, color: AppTheme.textHint(context)),
                      ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowColor(context).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: AppTheme.borderColor(context).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: AppTheme.primaryColor),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary(context),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20, left: 4),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subValue;

  const _InfoRow({required this.label, required this.value, this.subValue});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary(context),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subValue != null && subValue!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'S/N: $subValue',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textHint(context),
                        fontFamily: 'Monospace',
                        letterSpacing: -0.2,
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
}

