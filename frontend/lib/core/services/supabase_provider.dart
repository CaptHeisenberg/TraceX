import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Live Machine Heartbeat & Telemetry Status Provider (Single Row, id = 1)
final machineStatusProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return Supabase.instance.client
      .from('machine_status')
      .stream(primaryKey: ['id'])
      .eq('id', 1)
      .map((list) => list.isNotEmpty ? list.first : {});
});

// Live Statistics Summary Provider (Single Row, id = 1)
final statisticsSummaryProvider = StreamProvider<Map<String, dynamic>>((ref) {
  return Supabase.instance.client
      .from('statistics_summary')
      .stream(primaryKey: ['id'])
      .eq('id', 1)
      .map((list) => list.isNotEmpty ? list.first : {});
});

// Live Inspection Board runs Provider (Multiple Rows)
final inspectionsProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('inspections')
      .stream(primaryKey: ['board_id'])
      .order('created_at', ascending: false);
});

// Live Line Activity log stream Provider (Multiple Rows)
final activitiesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('activities')
      .stream(primaryKey: ['created_at'])
      .order('created_at', ascending: false);
});
