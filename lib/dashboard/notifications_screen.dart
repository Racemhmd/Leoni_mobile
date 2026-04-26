import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/notifications_service.dart';
import '../theme/design_system.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationsService();
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    final data = await _service.getAll();
    setState(() {
      _notifications = data;
      _isLoading = false;
    });
  }

  Future<void> _markAsRead(int index, int id) async {
    await _service.markAsRead(id);
    setState(() {
      _notifications[index]['isRead'] = true;
    });
  }

  Future<void> _markAllAsRead() async {
    await _service.markAllAsRead();
    setState(() {
      for (var n in _notifications) {
        n['isRead'] = true;
      }
    });
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'POINT_GAIN':
        return Icons.star;
      case 'POINT_LOSS':
        return Icons.warning_amber_rounded;
      case 'LEAVE_UPDATE':
        return Icons.event_available;
      case 'REMINDER':
        return Icons.access_time;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'POINT_GAIN':
        return AppColors.success;
      case 'POINT_LOSS':
        return AppColors.error;
      case 'LEAVE_UPDATE':
        return AppColors.primary;
      case 'REMINDER':
        return AppColors.secondary;
      default:
        return AppColors.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Notifications', style: AppTypography.headerMedium.copyWith(color: AppColors.primary)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        actions: [
          TextButton(
            onPressed: _markAllAsRead,
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? Center(child: Text('No notifications', style: AppTypography.bodyLarge))
              : ListView.builder(
                  padding: AppSpacing.pagePadding,
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final item = _notifications[index];
                    final isRead = item['isRead'] == true;
                    final date = DateTime.tryParse(item['createdAt'] ?? '') ?? DateTime.now();

                    return Card(
                      color: isRead ? Colors.white : AppColors.secondary.withOpacity(0.05),
                      margin: const EdgeInsets.only(bottom: AppSpacing.s),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSpacing.m),
                        side: BorderSide(color: isRead ? Colors.transparent : AppColors.primary.withOpacity(0.3)),
                      ),
                      elevation: 0,
                      child: ListTile(
                        onTap: () {
                          if (!isRead) {
                            _markAsRead(index, item['id']);
                          }
                        },
                        leading: CircleAvatar(
                          backgroundColor: _getColorForType(item['type']).withOpacity(0.1),
                          child: Icon(_getIconForType(item['type']), color: _getColorForType(item['type'])),
                        ),
                        title: Text(
                          item['title'] ?? 'Notification',
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(item['message'] ?? '', style: AppTypography.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('MMM d, yyyy - HH:mm').format(date),
                              style: AppTypography.bodySmall,
                            ),
                          ],
                        ),
                        trailing: !isRead
                            ? Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
