import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/theme.dart';
import '../../auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _fcmDefects = true;
  bool _fcmHealth = true;
  bool _fcmReports = false;

  void _handleLogout() async {
    // Show confirmation
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Text(
          'LOGOUT PLATFORM',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.critical),
        ),
        content: Text(
          'Are you sure you want to end your active supervisor session on TraceX?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).logout();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.critical),
            child: const Text('LOGOUT'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'SETTINGS & PROFILE',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Profile Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Text(
                      user?.name.substring(0, 1).toUpperCase() ?? 'S',
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Line Supervisor',
                          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          user?.email ?? 'operator@tracex.com',
                          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Notification Rules Toggles
            Text(
              'PUSH ALERTS RULES (FCM)',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    value: _fcmDefects,
                    activeColor: AppColors.primary,
                    title: Text('Critical Defect Alarms', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text('Receive alerts immediately when critical component faults are optical-scanned.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    onChanged: (val) {
                      setState(() {
                        _fcmDefects = val;
                      });
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    value: _fcmHealth,
                    activeColor: AppColors.primary,
                    title: Text('Factory Health Drops', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text('Receive alert thresholds when factory yield fall below target percentage.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    onChanged: (val) {
                      setState(() {
                        _fcmHealth = val;
                      });
                    },
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    value: _fcmReports,
                    activeColor: AppColors.primary,
                    title: Text('New Batch Reports', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500)),
                    subtitle: Text('Alert when compilation reports are ready for dispatching.', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                    onChanged: (val) {
                      setState(() {
                        _fcmReports = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Theme Settings
            Text(
              'SYSTEM CONFIGURATIONS',
              style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
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
                children: [
                  _buildOptionRow('Active Theme', 'Industrial Dark Mode Only (Static)'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildOptionRow('App Language', 'English (United States)'),
                  const Divider(color: AppColors.border, height: 20),
                  _buildOptionRow('App Version', 'v1.0.0 (Production Release)'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            ElevatedButton(
              onPressed: _handleLogout,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.critical.withOpacity(0.08),
                foregroundColor: AppColors.critical,
                side: const BorderSide(color: AppColors.critical, width: 1.2),
              ),
              child: const Text('DISCONNECT SESSION'),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
        Text(value, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
      ],
    );
  }
}
