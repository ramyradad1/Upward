import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import '../models/audit_session_model.dart';
import '../models/location_model.dart';
import '../services/audit_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';

class AuditScreen extends StatefulWidget {
  const AuditScreen({super.key});

  @override
  State<AuditScreen> createState() => _AuditScreenState();
}

class _AuditScreenState extends State<AuditScreen> with SingleTickerProviderStateMixin {
  // Controllers
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );
  
  // State
  AuditSessionModel? _currentSession;
  List<LocationModel> _locations = [];
  LocationModel? _selectedLocation;
  bool _isLoading = false;
  
  // Animation
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadLocations();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() => _isLoading = true);
    final locations = await LocationService.getLocations();
    if (mounted) {
      setState(() {
        _locations = locations;
        _isLoading = false;
      });
    }
  }

  Future<void> _startSession() async {
    if (_selectedLocation == null) return;

    setState(() => _isLoading = true);
    final session = await AuditService.createSession(
      locationId: _selectedLocation!.id,
      locationName: _selectedLocation!.name,
    );

    if (mounted) {
      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
      _scannerController.start();
    }
  }

  Future<void> _completeSession() async {
    if (_currentSession == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Audit?'),
        content: const Text('This will mark the audit as completed and calculate missing items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Complete')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final completedSession = await AuditService.completeSession(_currentSession!);
    
    if (mounted) {
      setState(() {
        _currentSession = null;
        _selectedLocation = null;
        _isLoading = false;
      });
      _scannerController.stop();
      
      if (completedSession != null) {
        _showCompletionSummary(completedSession);
      }
    }
  }

  void _showCompletionSummary(AuditSessionModel session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor(context),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Audit Completed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              session.locationName ?? 'Unknown Location',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _buildStatRow(context, 'Matched', '${session.matchedCount}', Colors.green),
            _buildStatRow(context, 'Misplaced', '${session.misplacedCount}', Colors.orange),
            _buildStatRow(context, 'Missing', '${session.missingCount}', Colors.red),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 18,
              color: AppTheme.textPrimary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }



  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    
    if (permission == LocationPermission.deniedForever) return null;

    // Use passing position for speed if available, otherwise get current
    // getLastKnownPosition is faster
    return await Geolocator.getLastKnownPosition() ?? await Geolocator.getCurrentPosition();
  }

  void _onBarcodeDetect(BarcodeCapture capture) async {
    if (_currentSession == null) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    // Get location once for the batch scan
    final position = await _getCurrentLocation();

    for (final barcode in barcodes) {
      final String? code = barcode.rawValue;
      if (code == null || code.isEmpty) continue;
      
      final item = await AuditService.processScannedItem(
        sessionId: _currentSession!.id,
        session: _currentSession!,
        serialNumber: code,
        latitude: position?.latitude,
        longitude: position?.longitude,
      );
      
      if (mounted) {
        setState(() {
          final updatedItems = [..._currentSession!.scannedItems, item];
          _currentSession = _currentSession!.copyWith(scannedItems: updatedItems);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentSession == null) {
      return _buildSetupUI();
    }
    return _buildScanningUI();
  }

  Widget _buildSetupUI() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Audit'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.qr_code_scanner_rounded, size: 80, color: AppTheme.primaryColor),
            const SizedBox(height: 24),
            Text(
              'Select Location to Audit',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<LocationModel>(
                decoration: InputDecoration(
                  hintText: 'Choose Location',
                  hintStyle: TextStyle(color: AppTheme.textHint(context)),
                  filled: true,
                  fillColor: AppTheme.inputFill(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.inputBorder(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.inputBorder(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                initialValue: _selectedLocation,
                items: _locations.map((loc) {
                  return DropdownMenuItem(
                    value: loc,
                    child: Text(loc.name),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _selectedLocation = val),
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _selectedLocation == null ? null : _startSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Start Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningUI() {
    return Scaffold(
      body: Stack(
        children: [
          // Camera View
          MobileScanner(
            controller: _scannerController,
            onDetect: _onBarcodeDetect,
            overlayBuilder: (context, constraints) {
              return Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(40),
              );
            },
          ),
          
          // Header Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 16,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Auditing',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        _currentSession?.locationName ?? '...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.flash_on, color: Colors.white),
                    onPressed: () => _scannerController.toggleTorch(),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Stats & List
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 350,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor(context),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20)],
              ),
              child: Column(
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  
                  // Stats Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _statItem('Scanned', '${_currentSession?.totalScanned ?? 0}', Colors.blue),
                        _statItem('Matched', '${_currentSession?.matchedCount ?? 0}', Colors.green),
                        _statItem('Misplaced', '${_currentSession?.misplacedCount ?? 0}', Colors.orange),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 24),
                  
                  // Scanned List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _currentSession?.scannedItems.length ?? 0,
                      reverse: true, // Show newest at bottom (or top if we want) - actually standard list logs usually newest at bottom
                      itemBuilder: (context, index) {
                        // Reverse index to show newest at top if we want, or just standard
                        // Let's show newest at TOP.
                        final items = _currentSession!.scannedItems.reversed.toList();
                        final item = items[index];
                        
                        return ListTile(
                          leading: Text(item.resultEmoji, style: const TextStyle(fontSize: 24)),
                          title: Text(
                            item.assetName ?? 'Unknown Asset',
                            style: TextStyle(
                                color: AppTheme.textPrimary(context),
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            'S/N: ${item.serialNumber}',
                            style: TextStyle(color: AppTheme.textSecondary(context)),
                          ),
                          trailing: Text(
                            DateFormat.Hms().format(item.scannedAt),
                            style: TextStyle(color: AppTheme.textSecondary(context), fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // Complete Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _completeSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Complete Audit', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
