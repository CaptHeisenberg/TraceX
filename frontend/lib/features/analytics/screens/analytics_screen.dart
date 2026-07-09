import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/theme/theme.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  int _activeTimelineIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'MANUFACTURING ANALYTICS',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: analyticsState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (err, stack) => Center(child: Text('Operational connection error: $err')),
        data: (data) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Timeline yield chart selector
                _buildTimelineSelector(),
                const SizedBox(height: 16),

                // Yield rate curve card
                _buildYieldChartCard(data),
                const SizedBox(height: 24),

                // Defect counts and Heatmap side-by-side or stacked
                _buildTopDefectsCard(data),
                const SizedBox(height: 24),

                _buildDefectHeatmapCard(data),
                const SizedBox(height: 24),

                _buildLineYieldComparisonCard(data),
                const SizedBox(height: 48),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: ['DAILY YIELD', 'WEEKLY YIELD', 'MONTHLY YIELD'].map((label) {
          final idx = ['DAILY YIELD', 'WEEKLY YIELD', 'MONTHLY YIELD'].indexOf(label);
          final isActive = _activeTimelineIndex == idx;
          return Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTimelineIndex = idx;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.black : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildYieldChartCard(Map<String, dynamic> data) {
    List<FlSpot> spots = [];
    List<String> titles = [];

    if (_activeTimelineIndex == 0) {
      // Daily
      final yields = data['daily_yields'] as List<dynamic>? ?? [];
      spots = List.generate(yields.length, (i) {
        final val = (yields[i]['yield_rate'] as num).toDouble();
        return FlSpot(i.toDouble(), val);
      });
      titles = yields.map((e) => e['day'] as String).toList();
    } else if (_activeTimelineIndex == 1) {
      // Weekly
      final yields = data['weekly_yields'] as List<dynamic>? ?? [];
      spots = List.generate(yields.length, (i) {
        final val = (yields[i]['yield_rate'] as num).toDouble();
        return FlSpot(i.toDouble(), val);
      });
      titles = yields.map((e) => e['week'] as String).toList();
    } else {
      // Monthly
      final yields = data['monthly_yields'] as List<dynamic>? ?? [];
      spots = List.generate(yields.length, (i) {
        final val = (yields[i]['yield_rate'] as num).toDouble();
        return FlSpot(i.toDouble(), val);
      });
      titles = yields.map((e) => e['month'] as String).toList();
    }

    if (spots.isEmpty) {
      spots = [const FlSpot(0, 95.0), const FlSpot(1, 96.0), const FlSpot(2, 94.5)];
      titles = ['A', 'B', 'C'];
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AOI YIELD TREND CURVE (%)',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final idx = val.toInt();
                        if (idx >= 0 && idx < titles.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(titles[idx], style: const TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      getTitlesWidget: _leftTitlesWidget,
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 85,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.06),
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

  static Widget _leftTitlesWidget(double value, TitleMeta meta) {
    if (value % 5 == 0) {
      return Text('${value.toInt()}%', style: const TextStyle(fontSize: 10, color: AppColors.textSecondary));
    }
    return const SizedBox();
  }

  Widget _buildTopDefectsCard(Map<String, dynamic> data) {
    final topDefects = data['top_defects'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP COMPONENT DEFECT CLASSIFICATIONS',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 20),
          ...topDefects.map((def) {
            final name = def['defect'] as String;
            final count = def['count'] as int;
            // Let's assume max count in set for scaling
            final double scaleVal = count / 15.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text(count.toString(), style: GoogleFonts.outfit(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: scaleVal.clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.border,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDefectHeatmapCard(Map<String, dynamic> data) {
    final coords = data['heatmap_data'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PCB HEAT MAP (DEFECT DENSITY MATRIX)',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          
          // PCB board mockup showing coordinate cluster dots
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: const Color(0xFF070B08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                // Draw some circuit boards background grid line
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.25,
                    child: GridPaper(
                      color: AppColors.success.withOpacity(0.4),
                      divisions: 1,
                      subdivisions: 1,
                    ),
                  ),
                ),
                // Draw coordinates dots
                ...coords.map((c) {
                  final x = (c['x'] as num).toDouble();
                  final y = (c['y'] as num).toDouble();
                  final intensity = (c['intensity'] as num).toDouble();
                  final component = c['component'] as String;

                  return Positioned(
                    left: (x / 100.0) * 300,
                    top: (y / 100.0) * 160,
                    child: Container(
                      height: 16,
                      width: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.critical.withOpacity(intensity * 0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        height: 6,
                        width: 6,
                        decoration: const BoxDecoration(color: AppColors.critical, shape: BoxShape.circle),
                      ),
                    ),
                  );
                }),
                
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Text(
                    'High density clusters on SMT feed areas',
                    style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineYieldComparisonCard(Map<String, dynamic> data) {
    final lines = data['line_status'] as List<dynamic>? ?? [];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PRODUCTION LINE METRIC AUDITS',
            style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
          ),
          const SizedBox(height: 16),
          ...lines.map((l) {
            final name = l['line'] as String;
            final speed = l['speed'] as int;
            final yieldRate = (l['yield_rate'] as num).toDouble();
            final status = l['status'] as String;
            final isActive = status == 'Active';

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700)),
                      Text('Speed: $speed PCH | Status: $status', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.success.withOpacity(0.08) : AppColors.warning.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isActive ? AppColors.success.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
                    ),
                    child: Text(
                      '${yieldRate.toStringAsFixed(1)}% Yield',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isActive ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
