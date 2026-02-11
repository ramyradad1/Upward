import 'package:flutter_test/flutter_test.dart';
import 'package:stitch_app/services/analytics_service.dart';

void main() {
  group('AnalyticsService Tests', () {
    test('processStatusCounts counts correctly', () {
      final assets = [
        {'status': 'available'},
        {'status': 'available'},
        {'status': 'in_use'},
        {'status': null}, // Should default to available
        {'status': 'retired'},
      ];

      final counts = AnalyticsService.processStatusCounts(assets);

      expect(counts['available'], 3); // 2 explicit + 1 null
      expect(counts['in_use'], 1);
      expect(counts['retired'], 1);
      expect(counts['maintenance'], 0);
    });

    test('processCategoryCounts counts correctly', () {
      final assets = [
        {'category': 'Laptop'},
        {'category': 'Laptop'},
        {'category': 'Monitor'},
        {'category': null}, // Should count as Other
      ];

      final counts = AnalyticsService.processCategoryCounts(assets);

      expect(counts['Laptop'], 2);
      expect(counts['Monitor'], 1);
      expect(counts['Other'], 1);
    });

    test('processRequestStats counts correctly', () {
      final requests = [
        {'status': 'pending'},
        {'status': 'approved'},
        {'status': 'approved'},
        {'status': 'rejected'},
        {'status': null}, // Should default to pending
      ];

      final stats = AnalyticsService.processRequestStats(requests);

      expect(stats['pending'], 2);
      expect(stats['approved'], 2);
      expect(stats['rejected'], 1);
    });
  });
}
