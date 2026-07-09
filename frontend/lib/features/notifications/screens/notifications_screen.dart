import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/theme.dart';
import '../providers/notifications_provider.dart';
import '../../../models/notification.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.text),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'PLATFORM ALARM LOGS',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () => ref.read(notificationsProvider.notifier).fetchNotifications(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: notificationsState.when(
        loading: () => _buildShimmerFeed(),
        error: (err, stack) => _buildErrorState(ref),
        data: (notifications) => notifications.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: () async {
                  await ref.read(notificationsProvider.notifier).fetchNotifications();
                },
                color: AppColors.primary,
                backgroundColor: AppColors.card,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final notification = notifications[index];
                    return _buildNotificationCard(context, ref, notification);
                  },
                ),
              ),
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, WidgetRef ref, SystemNotification item) {
    final isUnread = item.status == 'unread';
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(item.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnread ? AppColors.primary.withOpacity(0.4) : AppColors.border,
          width: isUnread ? 1.2 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (isUnread) {
            ref.read(notificationsProvider.notifier).markAsRead(item.id);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // State Indicator Icon
              Container(
                height: 36,
                width: 36,
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppColors.primary.withOpacity(0.08)
                      : AppColors.border.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isUnread ? Icons.notifications_active : Icons.notifications_none,
                  color: isUnread ? AppColors.primary : AppColors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                              color: isUnread ? AppColors.text : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (isUnread)
                          Container(
                            height: 6,
                            width: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.message,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isUnread ? AppColors.text : AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateStr,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerFeed() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      itemCount: 4,
      itemBuilder: (context, index) => Container(
        height: 90,
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined, color: AppColors.textMuted, size: 64),
          const SizedBox(height: 16),
          Text(
            'Notification Log Clear',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            'No alarms or system logs are active at this moment.',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.critical, size: 48),
          const SizedBox(height: 16),
          Text(
            'Connection Error',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              ref.read(notificationsProvider.notifier).fetchNotifications();
            },
            child: const Text('RELOAD ALARMS'),
          ),
        ],
      ),
    );
  }
}
