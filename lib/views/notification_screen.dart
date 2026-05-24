import 'package:bike_shop/config/responsive.dart';
import 'package:bike_shop/config/theme.dart';
import 'package:bike_shop/viewmodels/notification_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationProvider>().markAllAsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        elevation: 0,
        actions: [
          if (notifications.isNotEmpty)
            IconButton(
              icon: Icon(
                Icons.clear_all,
                color: colorScheme.onSurface.withValues(alpha: 0.54),
              ),
              onPressed: () => provider.clearAll(),
              tooltip: 'Clear all',
            ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 64,
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Payment notifications will appear here',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.38),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.horizontalPadding(context),
                vertical: 16,
              ),
              itemCount: notifications.length,
              itemBuilder: (ctx, index) {
                final notif = notifications[index];
                final isRead = notif['isRead'] == 'true';
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: isRead
                        ? null
                        : Border.all(color: AppTheme.accentBlue, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.notifications_active,
                            color: isRead
                                ? colorScheme.onSurface.withValues(alpha: 0.54)
                                : AppTheme.accentBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              notif['title'] ?? 'Notification',
                              style: TextStyle(
                                color: isRead
                                    ? colorScheme.onSurface.withValues(
                                        alpha: 0.7,
                                      )
                                    : colorScheme.onSurface,
                                fontWeight: isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            notif['time'] ?? '',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.38,
                              ),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notif['body'] ?? '',
                        style: TextStyle(
                          color: isRead
                              ? colorScheme.onSurface.withValues(alpha: 0.54)
                              : colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
