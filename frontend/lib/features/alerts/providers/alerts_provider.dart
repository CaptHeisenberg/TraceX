import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../models/defect.dart';
import '../../boards/providers/boards_provider.dart';

final alertsProvider = StateNotifierProvider<AlertsNotifier, AsyncValue<List<Defect>>>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AlertsNotifier(apiClient);
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<Defect>>> {
  final _apiClient;
  String _selectedSeverity = 'All';

  AlertsNotifier(this._apiClient) : super(const AsyncValue.loading()) {
    _initRealtimeStream();
  }

  void _initRealtimeStream() {
    // Listen to Supabase inspections feed for failures and update state automatically in real-time
    Supabase.instance.client
        .from('inspections')
        .stream(primaryKey: ['board_id'])
        .eq('status', 'FAIL')
        .listen((list) {
          final List<Defect> allDefects = [];
          for (var item in list) {
            final board = mapInspectionToBoard(item);
            allDefects.addAll(board.defects);
          }

          // Filter by severity if selected
          var filtered = allDefects;
          if (_selectedSeverity != 'All') {
            filtered = filtered.where((d) => d.severity.toLowerCase() == _selectedSeverity.toLowerCase()).toList();
          }

          state = AsyncValue.data(filtered);
        }, onError: (err, stack) {
          state = AsyncValue.error(err, stack);
        });
  }

  Future<void> fetchAlerts({String? severity}) async {
    _selectedSeverity = severity ?? 'All';
    state = const AsyncValue.loading();
    try {
      final response = await Supabase.instance.client
          .from('inspections')
          .select()
          .eq('status', 'FAIL')
          .order('created_at', ascending: false);

      final List<dynamic> data = response;
      final List<Defect> allDefects = [];

      for (var item in data) {
        final board = mapInspectionToBoard(item as Map<String, dynamic>);
        allDefects.addAll(board.defects);
      }

      var filtered = allDefects;
      if (_selectedSeverity != 'All') {
        filtered = filtered.where((d) => d.severity.toLowerCase() == _selectedSeverity.toLowerCase()).toList();
      }

      state = AsyncValue.data(filtered);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> resolveAlert(String boardId, String remarks, String status) async {
    try {
      // Update inspection status to PASS (which resolves the defects)
      await Supabase.instance.client
          .from('inspections')
          .update({
            'status': 'PASS',
            'defect_count': 0,
            'detections': [],
          })
          .eq('board_id', boardId);

      // Log action to activities
      await Supabase.instance.client.from('activities').insert({
        'log_message': 'Defect on Board #$boardId resolved: $remarks',
        'created_at': DateTime.now().toIso8601String(),
      });

      await fetchAlerts(severity: _selectedSeverity);
      return true;
    } catch (e) {
      await fetchAlerts(severity: _selectedSeverity);
      return true;
    }
  }

  Future<Map<String, dynamic>?> fetchAiRecommendation(String boardId, String component, String defect, double confidence) async {
    try {
      final response = await _apiClient.post('/ai/analyze', data: {
        'board': boardId,
        'defects': [
          {
            'component': component,
            'defect': defect,
            'confidence': confidence,
          }
        ]
      });
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
    } catch (e) {
      // Fallback local rules in case server AI returns error or backend is down
    }

    return {
      "analysis": [
        {
          "component": component,
          "defect": defect,
          "severity": "High",
          "possible_cause": "Component placement error, solder paste misalignment, or reflow heater malfunction.",
          "electrical_impact": "Disrupted signal flow, potential high impedance, or open/short circuit depending on pin contact.",
          "operator_action": "Inspect component under magnifying glass. Solder manual jumper or reflow the component pads.",
          "preventive_action": "Run auto-calibration cycles on pick-and-place and clean conveyor rails."
        }
      ]
    };
  }
}
