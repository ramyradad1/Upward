import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/asset_service.dart';
import '../services/profile_service.dart';
import '../models/asset_model.dart';

import '../theme/app_theme.dart';

class MyCustodyScreen extends StatefulWidget {
  const MyCustodyScreen({super.key});

  @override
  State<MyCustodyScreen> createState() => _MyCustodyScreenState();
}

class _MyCustodyScreenState extends State<MyCustodyScreen> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = ProfileService.getCurrentProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Custody'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _profileFuture,
        builder: (context, profileSnapshot) {
          if (profileSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = profileSnapshot.data;
          if (profile == null) {
            return const Center(
              child: Text('User profile not found. Please login again.'),
            );
          }

          final userName = profile['name'] ?? profile['email'];
          if (userName == null) {
            return const Center(child: Text('User identity missing.'));
          }

          return StreamBuilder<List<AssetModel>>(
            stream: AssetService.getAssetsStreamForUser(userName.toString()),
            builder: (context, assetSnapshot) {
              if (assetSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (assetSnapshot.hasError) {
                return Center(child: Text('Error: ${assetSnapshot.error}'));
              }

              final myAssets = assetSnapshot.data ?? [];

              if (myAssets.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: myAssets.length,
                itemBuilder: (context, index) =>
                    _buildAssetCard(myAssets[index]),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No assets assigned to you',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              context.push('/requests/create');
            },
            icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
            label: const Text('Request New Device', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(AssetModel asset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: InkWell(
        onTap: () {
          context.push('/assets/details', extra: asset);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Asset Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: asset.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Asset Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          asset.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'S/N: ${asset.serialNumber}',
                          style: TextStyle(
                            color: AppTheme.textSecondary(context),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'ASSIGNED TO YOU',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                   _buildActionButton(
                    icon: Icons.report_problem_outlined,
                    label: 'Report Issue',
                    color: Colors.orange,
                    onTap: () => _reportIssue(asset),
                  ),
                  Container(width: 1, height: 24, color: AppTheme.borderColor(context)),
                  _buildActionButton(
                    icon: Icons.assignment_return_outlined,
                    label: 'Return Asset',
                    color: Colors.red,
                    onTap: () => _returnAsset(asset),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reportIssue(AssetModel asset) {
    // Navigate to create request screen with 'repair' type pre-selected
    // For now showing simple dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text('Please create a repair request describing the issue.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/requests/create');
            },
            child: const Text('Create Request'),
          ),
        ],
      ),
    );
  }

  void _returnAsset(AssetModel asset) {
    // Navigate to create request screen with 'return' type pre-selected
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Return Asset'),
        content: Text('Are you sure you want to return ${asset.name}? This will create a return request.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.push('/requests/create');
            },
            child: const Text('Proceed', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
