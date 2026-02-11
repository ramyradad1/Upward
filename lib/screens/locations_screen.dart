import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import 'location_details_screen.dart';

class LocationsScreen extends StatefulWidget {
  const LocationsScreen({super.key});

  @override
  State<LocationsScreen> createState() => _LocationsScreenState();
}

class _LocationsScreenState extends State<LocationsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String? _companyId;

  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animController.forward();
    _searchController.addListener(_onSearchChanged);
    _loadCompanyId();
  }

  Future<void> _loadCompanyId() async {
    final profile = await ProfileService.getCurrentProfile();
    if (mounted && profile != null) {
      setState(() {
        _companyId = profile['company_id'];
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  List<LocationModel> _filterLocations(List<LocationModel> locations) {
    if (_searchQuery.isEmpty) return locations;
    return locations
        .where((l) =>
            l.name.toLowerCase().contains(_searchQuery) ||
            LocationModel.typeToString(l.type)
                .toLowerCase()
                .contains(_searchQuery))
        .toList();
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

  Future<void> _showAddEditDialog({LocationModel? location}) async {
    final nameController =
        TextEditingController(text: location?.name ?? '');
    final addressController =
        TextEditingController(text: location?.address ?? '');
    LocationType selectedType = location?.type ?? LocationType.branch;
    String? selectedParentId = location?.parentId;

    // Fetch all locations for parent picker
    final allLocations = await LocationService.getLocations();

    if (!mounted) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: AppTheme.cardColor(ctx),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient(),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_typeIcon(selectedType),
                      color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  location == null ? 'Add Location' : 'Edit Location',
                  style: TextStyle(
                    color: AppTheme.textPrimary(ctx),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name
                  _buildTextField(ctx, nameController, 'Location Name',
                      Icons.label_rounded),
                  const SizedBox(height: 16),

                  // Type dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassColor(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppTheme.borderColor(ctx)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<LocationType>(
                        value: selectedType,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardColor(ctx),
                        style: TextStyle(
                            color: AppTheme.textPrimary(ctx)),
                        items: LocationType.values.map((t) {
                          return DropdownMenuItem(
                            value: t,
                            child: Row(
                              children: [
                                Icon(_typeIcon(t),
                                    size: 18, color: _typeColor(t)),
                                const SizedBox(width: 8),
                                Text(LocationModel.typeToString(t)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedType = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Parent Location dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.glassColor(ctx),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppTheme.borderColor(ctx)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String?>(
                        value: selectedParentId,
                        isExpanded: true,
                        dropdownColor: AppTheme.cardColor(ctx),
                        style: TextStyle(
                            color: AppTheme.textPrimary(ctx)),
                        hint: Row(
                          children: [
                            Icon(Icons.account_tree_rounded,
                                size: 18,
                                color: AppTheme.textHint(ctx)),
                            const SizedBox(width: 8),
                            Text('No Parent (Root)',
                                style: TextStyle(
                                    color: AppTheme.textHint(ctx))),
                          ],
                        ),
                        items: [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Row(
                              children: [
                                Icon(Icons.home_rounded,
                                    size: 18,
                                    color: AppTheme.textHint(ctx)),
                                const SizedBox(width: 8),
                                Text('No Parent (Root)',
                                    style: TextStyle(
                                        color: AppTheme.textHint(ctx))),
                              ],
                            ),
                          ),
                          ...allLocations
                              .where((l) => l.id != location?.id)
                              .map((l) {
                            return DropdownMenuItem<String?>(
                              value: l.id,
                              child: Row(
                                children: [
                                  Icon(_typeIcon(l.type),
                                      size: 18,
                                      color: _typeColor(l.type)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(l.name,
                                        overflow:
                                            TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        onChanged: (val) {
                          setDialogState(() {
                            selectedParentId = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _buildTextField(ctx, addressController,
                      'Address (Optional)', Icons.location_on_rounded),
                ],
              ),
            ),
            actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: AppTheme.textSecondary(ctx),
                        fontWeight: FontWeight.w600)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(location == null ? 'Add' : 'Save'),
                ),
              ),
            ],
          );
        },
      ),
    );

    if (result != true) return;

    final name = nameController.text.trim();
    if (name.isEmpty) {
      _showSnack('Name is required', isError: true);
      return;
    }

    if (_companyId == null) {
      // Try loading again
      await _loadCompanyId();
      if (_companyId == null) {
        if (mounted) _showSnack('Company not loaded. Please try again.', isError: true);
        return;
      }
    }

    if (location == null) {
      // Create
      final newLoc = LocationModel(
        id: '',
        companyId: _companyId!,
        name: name,
        type: selectedType,
        parentId: selectedParentId,
        address: addressController.text.trim().isNotEmpty
            ? addressController.text.trim()
            : null,
      );
      final created = await LocationService.createLocation(newLoc);
      if (mounted) {
        if (created != null) {
          _showSnack('Location added');
        } else {
          _showSnack('Failed to add location', isError: true);
        }
      }
    } else {
      // Update
      final updated = location.copyWith(
        name: name,
        type: selectedType,
        parentId: selectedParentId,
        address: addressController.text.trim().isNotEmpty
            ? addressController.text.trim()
            : null,
      );
      final success = await LocationService.updateLocation(updated);
      if (mounted) {
        if (success) {
          _showSnack('Location updated');
        } else {
          _showSnack('Failed to update location', isError: true);
        }
      }
    }
  }

  Widget _buildTextField(BuildContext ctx, TextEditingController controller,
      String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.glassColor(ctx),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor(ctx)),
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(color: AppTheme.textPrimary(ctx)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: AppTheme.textHint(ctx), fontSize: 14),
          prefixIcon:
              Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.6)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Future<void> _deleteLocation(LocationModel location) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardColor(ctx),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentWarm.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning_amber_rounded,
                  color: AppTheme.accentWarm, size: 24),
            ),
            const SizedBox(width: 12),
            Text('Delete Location',
                style: TextStyle(
                  color: AppTheme.textPrimary(ctx),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                )),
          ],
        ),
        content: Text(
            'Are you sure you want to delete "${location.name}"?\nAll child locations will become root.',
            style: TextStyle(
                color: AppTheme.textSecondary(ctx), fontSize: 15)),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(
                    color: AppTheme.textSecondary(ctx),
                    fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentWarm,
              foregroundColor: Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await LocationService.deleteLocation(location.id);
      if (mounted) {
        if (success) {
          _showSnack('Location deleted');
        } else {
          _showSnack('Failed to delete location', isError: true);
        }
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.accentWarm : AppTheme.accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.backgroundGradient(context),
            ),
          ),
          SafeArea(
            child: StreamBuilder<List<LocationModel>>(
              stream: LocationService.getLocationsStream(),
              builder: (context, snapshot) {
                final allLocations = snapshot.data ?? [];
                final filteredLocations = _filterLocations(allLocations);
                final isLoading = snapshot.connectionState ==
                        ConnectionState.waiting &&
                    snapshot.data == null;

                // Build tree for display
                final tree = LocationService.buildTree(filteredLocations);

                return Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 24, 0),
                      child: Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.glassColor(context),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: AppTheme.borderColor(context)),
                            ),
                            child: IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: AppTheme.textPrimary(context),
                                  size: 18),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            'Locations',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: AppTheme.primaryColor
                                      .withValues(alpha: 0.2)),
                            ),
                            child: Text(
                              '${allLocations.length}',
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.glassColor(context),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.borderColor(context)),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.shadowColor(context),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          style: TextStyle(
                              color: AppTheme.textPrimary(context)),
                          decoration: InputDecoration(
                            hintText: 'Search locations...',
                            hintStyle: TextStyle(
                              color: AppTheme.textHint(context),
                              fontSize: 14,
                            ),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: AppTheme.primaryColor
                                    .withValues(alpha: 0.6)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 16),
                          ),
                        ),
                      ),
                    ),

                    // Locations Tree / List
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primaryColor))
                          : filteredLocations.isEmpty
                              ? _buildEmptyState()
                              : _searchQuery.isNotEmpty
                                  ? _buildFlatList(filteredLocations)
                                  : _buildTreeView(tree),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: AppTheme.primaryGradient(),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddEditDialog(),
          backgroundColor: Colors.transparent,
          elevation: 0,
          highlightElevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Add Location',
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.white)),
        ),
      ),
    );
  }

  Widget _buildTreeView(List<LocationNode> roots) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: roots.length,
      itemBuilder: (context, index) {
        return _buildTreeNode(roots[index], 0, index);
      },
    );
  }

  Widget _buildTreeNode(LocationNode node, int depth, int index) {
    // Stagger animation
    final start = (index * 0.08).clamp(0.0, 1.0);
    final end = (start + 0.4).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _animController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    final color = _typeColor(node.location.type);

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2),
        end: Offset.zero,
      ).animate(anim),
      child: FadeTransition(
        opacity: anim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: EdgeInsets.only(
                  left: depth * 20.0, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.glassColor(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor(context)),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.shadowColor(context),
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
                      AppTheme.slideRoute(LocationDetailsScreen(location: node.location)),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        // Type icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                color,
                                color.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(_typeIcon(node.location.type),
                              color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        // Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                node.location.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color:
                                      AppTheme.textPrimary(context),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Container(
                                    padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2),
                                    decoration: BoxDecoration(
                                      color: color
                                          .withValues(alpha: 0.1),
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      LocationModel.typeToString(
                                          node.location.type),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                  if (node.children.isNotEmpty) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                        Icons
                                            .subdirectory_arrow_right_rounded,
                                        size: 14,
                                        color: AppTheme.textHint(
                                            context)),
                                    const SizedBox(width: 2),
                                    Text(
                                      '${node.children.length}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textHint(
                                            context),
                                      ),
                                    ),
                                  ],
                                  if (node.location.address !=
                                      null) ...[
                                    const SizedBox(width: 8),
                                    Icon(
                                        Icons
                                            .location_on_outlined,
                                        size: 14,
                                        color: AppTheme.textHint(
                                            context)),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Edit
                        IconButton(
                          icon: Icon(
                              Icons.edit_rounded,
                              color: AppTheme.primaryColor.withValues(alpha: 0.8),
                              size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () => _showAddEditDialog(location: node.location),
                        ),
                        const SizedBox(width: 8),
                        // Delete
                        IconButton(
                          icon: Icon(
                              Icons.delete_outline_rounded,
                              color: AppTheme.accentWarm.withValues(alpha: 0.8),
                              size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppTheme.accentWarm.withValues(alpha: 0.08),
                            padding: const EdgeInsets.all(8),
                          ),
                          onPressed: () =>
                              _deleteLocation(node.location),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Children
            ...node.children.asMap().entries.map((entry) =>
                _buildTreeNode(entry.value, depth + 1, index + entry.key + 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildFlatList(List<LocationModel> locations) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
      itemCount: locations.length,
      itemBuilder: (context, index) {
        final loc = locations[index];
        final color = _typeColor(loc.type);

        final start = (index * 0.08).clamp(0.0, 1.0);
        final end = (start + 0.4).clamp(0.0, 1.0);
        final anim = CurvedAnimation(
          parent: _animController,
          curve: Interval(start, end, curve: Curves.easeOutCubic),
        );

        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.2),
            end: Offset.zero,
          ).animate(anim),
          child: FadeTransition(
            opacity: anim,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.glassColor(context),
                borderRadius: BorderRadius.circular(16),
                border:
                    Border.all(color: AppTheme.borderColor(context)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  onTap: () =>
                      _showAddEditDialog(location: loc),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withValues(alpha: 0.7)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_typeIcon(loc.type),
                        color: Colors.white, size: 20),
                  ),
                  title: Text(loc.name,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary(context))),
                  subtitle: Text(
                      LocationModel.typeToString(loc.type),
                      style: TextStyle(
                          color: AppTheme.textSecondary(context),
                          fontSize: 12)),
                  trailing: IconButton(
                    icon: Icon(Icons.delete_outline_rounded,
                        color: AppTheme.accentWarm
                            .withValues(alpha: 0.8),
                        size: 20),
                    onPressed: () => _deleteLocation(loc),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.location_off_rounded,
                size: 48,
                color: AppTheme.primaryColor.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No locations yet'
                : 'No matching locations',
            style: TextStyle(
              color: AppTheme.textSecondary(context),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchController.text.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Tap + to add a branch, room, or rack',
              style: TextStyle(
                color: AppTheme.textHint(context),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
