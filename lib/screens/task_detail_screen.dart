import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../theme/app_theme.dart';
import 'add_edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');
    final isOverdue = task.dueDateTime.isBefore(DateTime.now());
    final priorityColor = AppTheme.getPriorityColor(task.priority.index);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            onPressed: () => _editTask(context),
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit',
          ),
          IconButton(
            onPressed: () => _deleteTask(context),
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            tooltip: 'Delete',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Type badge + priority
            Row(
              children: [
                _buildTypeBadge(),
                const SizedBox(width: 12),
                _buildPriorityBadge(priorityColor),
                if (task.recurringType != RecurringType.none) ...[
                  const SizedBox(width: 12),
                  _buildRecurringBadge(),
                ],
              ],
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              task.title,
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontSize: 24),
            ),

            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                task.description,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.6,
                    ),
              ),
            ],

            const SizedBox(height: 28),

            // Info cards
            _buildInfoCard(
              context,
              icon: isOverdue ? Icons.warning_amber_rounded : Icons.calendar_today_rounded,
              iconColor: isOverdue ? AppTheme.error : AppTheme.primaryColor,
              title: 'Due Date',
              value: dateFormat.format(task.dueDateTime),
              subtitle: isOverdue ? 'OVERDUE' : null,
              subtitleColor: AppTheme.error,
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              context,
              icon: Icons.access_time_rounded,
              iconColor: AppTheme.accentColor,
              title: 'Due Time',
              value: timeFormat.format(task.dueDateTime),
            ),

            const SizedBox(height: 12),

            _buildInfoCard(
              context,
              icon: Icons.label_rounded,
              iconColor: AppTheme.primaryLight,
              title: 'Category',
              value: task.category,
            ),

            if (task.taskType == TaskType.reminder) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                icon: Icons.timer_outlined,
                iconColor: AppTheme.reminderColor,
                title: 'Reminder Interval',
                value: 'Every ${task.reminderIntervalMinutes} minutes',
                subtitle: 'Until marked done',
              ),
            ],

            if (task.recurringType != RecurringType.none) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                icon: Icons.repeat_rounded,
                iconColor: AppTheme.accentColor,
                title: 'Recurring',
                value: task.recurringLabel,
              ),
            ],

            const SizedBox(height: 32),

            // Complete button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _completeTask(context),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'Mark as Complete',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isAlarm = task.taskType == TaskType.alarm;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: isAlarm ? AppTheme.alarmGradient : AppTheme.reminderGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAlarm ? Icons.alarm : Icons.notifications_active_outlined,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 6),
          Text(
            task.taskTypeLabel,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriorityBadge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            task.priorityLabel,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecurringBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.accentColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 14, color: AppTheme.accentColor),
          const SizedBox(width: 6),
          Text(
            task.recurringLabel,
            style: const TextStyle(
              color: AppTheme.accentColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.bgCardLight),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor ?? AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editTask(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => AddEditTaskScreen(task: task)),
    );
  }

  void _deleteTask(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Permanently delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<TaskProvider>().deleteTask(task.id!);
      if (context.mounted) Navigator.pop(context);
    }
  }

  void _completeTask(BuildContext context) async {
    await context.read<TaskProvider>().completeTask(task);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.recurringType != RecurringType.none
                      ? 'Completed! Next occurrence created.'
                      : 'Completed & deleted!',
                ),
              ),
            ],
          ),
        ),
      );
      Navigator.pop(context);
    }
  }
}
