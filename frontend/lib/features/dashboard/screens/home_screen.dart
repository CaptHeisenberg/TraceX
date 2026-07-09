import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/services/supabase_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).currentUser;
    final now = DateTime.now();
    final timeStr = DateFormat('HH:mm').format(now);
    final dateStr = DateFormat('EEE, MMM d').format(now);

    final machineStatusAsync = ref.watch(machineStatusProvider);
    final statisticsSummaryAsync = ref.watch(statisticsSummaryProvider);
    final activitiesAsync = ref.watch(activitiesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF090909),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(machineStatusProvider);
            ref.invalidate(statisticsSummaryProvider);
            ref.invalidate(activitiesProvider);
          },
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header (Greeting + Time)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME BACK,',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.name ?? 'Line Supervisor',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'TraceX Factory Floor — Line 1',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            timeStr,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            dateStr,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Wait for all three real-time streams
                if (machineStatusAsync.isLoading || statisticsSummaryAsync.isLoading || activitiesAsync.isLoading)
                  _buildShimmerLoader()
                else if (machineStatusAsync.hasError || statisticsSummaryAsync.hasError)
                  _buildErrorState(
                    'Failed to connect to Supabase: ${machineStatusAsync.error ?? statisticsSummaryAsync.error}',
                    ref,
                  )
                else
                  _buildDashboardContent(
                    context,
                    ref,
                    machineStatusAsync.value ?? {},
                    statisticsSummaryAsync.value ?? {},
                    activitiesAsync.value ?? [],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> machineStatus,
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> activities,
  ) {
    // Dynamic KPI summary extraction
    final totalBoards = stats['total_boards'] as int? ?? 0;
    final passBoards = stats['pass_boards'] as int? ?? 0;
    final failBoards = stats['fail_boards'] as int? ?? 0;
    final totalDefects = stats['total_defects'] as int? ?? 0;
    
    final yieldRate = totalBoards > 0 ? (passBoards / totalBoards) * 100.0 : 100.0;
    final healthScore = yieldRate; // Factory health mapped to yield rate

    String healthLabel = 'Excellent';
    Color healthColor = AppColors.success;
    if (healthScore < 75) {
      healthLabel = 'Critical';
      healthColor = AppColors.critical;
    } else if (healthScore < 90) {
      healthLabel = 'Warning';
      healthColor = AppColors.warning;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Machine Heartbeat & Telemetry Card
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.router_outlined, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'SYSTEM HEARTBEAT',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (machineStatus['online'] as bool? ?? false)
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.critical.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: (machineStatus['online'] as bool? ?? false)
                            ? AppColors.success
                            : AppColors.critical,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 6,
                          width: 6,
                          decoration: BoxDecoration(
                            color: (machineStatus['online'] as bool? ?? false)
                                ? AppColors.success
                                : AppColors.critical,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          (machineStatus['online'] as bool? ?? false) ? 'ONLINE' : 'OFFLINE',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: (machineStatus['online'] as bool? ?? false)
                                ? AppColors.success
                                : AppColors.critical,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(color: AppColors.border, height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryStat(
                      'MACHINE ID',
                      machineStatus['machine_id'] as String? ?? 'N/A',
                    ),
                  ),
                  Expanded(
                    child: _buildTelemetryStat(
                      'OPERATION MODE',
                      (machineStatus['running'] as bool? ?? false) ? 'RUNNING' : 'STOPPED',
                      valueColor: (machineStatus['running'] as bool? ?? false)
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTelemetryStat(
                      'CURRENT BOARD',
                      machineStatus['current_board'] as String? ?? 'NONE',
                    ),
                  ),
                  Expanded(
                    child: _buildTelemetryStat(
                      'INSPECTION STATE',
                      machineStatus['inspection_state'] as String? ?? 'IDLE',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 2. Factory Health Score banner
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    height: 70,
                    width: 70,
                    child: CircularProgressIndicator(
                      value: healthScore / 100.0,
                      strokeWidth: 7,
                      backgroundColor: AppColors.border,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                  ),
                  Text(
                    '${healthScore.round()}%',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'FACTORY HEALTH SCORE',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthLabel,
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: healthColor,
                      ),
                    ),
                    Text(
                      'Based on real-time visual inspection defect severity rates',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 3. Today's Stats grid
        Text(
          'TODAY\'S METRICS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Boards Inspected', totalBoards.toString(), Icons.developer_board, AppColors.primary),
            _buildStatCard('Passed Runs', passBoards.toString(), Icons.check_circle_outline, AppColors.success),
            _buildStatCard('Today\'s Yield', '${yieldRate.toStringAsFixed(1)}%', Icons.show_chart, AppColors.success),
            _buildStatCard('Critical Defects', totalDefects.toString(), Icons.error_outline_rounded, AppColors.critical),
          ],
        ),
        const SizedBox(height: 24),

        // 4. AI Co-Pilot Banner
        InkWell(
          onTap: () => context.push('/chat'),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.psychology_outlined,
                    color: AppColors.primary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SMT AI CO-PILOT ASSISTANT',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Troubleshoot component anomalies, calibrate line feeds, and query custom reflow diagnostics.',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 5. Quick Actions
        Text(
          'QUICK OPERATIONS',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.qr_code_scanner,
                label: 'Scan PCB',
                onTap: () => context.go('/boards?scan=true'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.analytics_outlined,
                label: 'Analytics',
                onTap: () => context.go('/analytics'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                context,
                icon: Icons.warning_amber_rounded,
                label: 'Defects',
                onTap: () => context.go('/alerts'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 6. Live activity feed from Supabase logs
        Text(
          'LIVE LINE ACTIVITY FEED',
          style: GoogleFonts.outfit(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: activities.isEmpty
                ? [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Text(
                        'No activity logs recorded yet.',
                        style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      ),
                    )
                  ]
                : activities.take(5).map((log) {
                    final msg = log['log_message'] as String? ?? '';
                    final createdAtStr = log['created_at'] as String? ?? '';
                    String timeStr = '00:00';
                    try {
                      if (createdAtStr.isNotEmpty) {
                        final dt = DateTime.parse(createdAtStr);
                        timeStr = DateFormat('HH:mm').format(dt.toLocal());
                      }
                    } catch (_) {}

                    Color statusColor = AppColors.primary;
                    if (msg.toLowerCase().contains('pass')) {
                      statusColor = AppColors.success;
                    } else if (msg.toLowerCase().contains('fail') || msg.toLowerCase().contains('defect')) {
                      statusColor = AppColors.critical;
                    }

                    return _buildActivityRow(timeStr, msg, statusColor);
                  }).toList(),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTelemetryStat(String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.text,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow(String time, String message, Color statusColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 14,
            width: 3,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (i) => Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
          )),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.critical.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 48),
          const SizedBox(height: 16),
          Text(
            'Operational Connection Error',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.invalidate(machineStatusProvider);
              ref.invalidate(statisticsSummaryProvider);
              ref.invalidate(activitiesProvider);
            },
            child: const Text('RETRY CONNECTION'),
          ),
        ],
      ),
    );
  }
}
