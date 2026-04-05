import 'package:flutter/material.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final VoidCallback onComplete;
  final VoidCallback onDelete;

  const TaskCard({
    super.key,
    required this.task,
    required this.onTap,
    required this.onComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppTheme.getPriorityColor(task.priority.index);
    final isOverdue = task.dueDateTime.isBefore(DateTime.now());
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Dismissible(
      key: Key('task_${task.id}'),
      background: _buildSwipeBackground(
        alignment: Alignment.centerLeft,
        color: AppTheme.success,
        icon: Icons.check_circle_outline,
        label: 'Complete',
      ),
      secondaryBackground: _buildSwipeBackground(
        alignment: Alignment.centerRight,
        color: AppTheme.error,
        icon: Icons.delete_outline,
        label: 'Delete',
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
          return false;
        } else {
          return await _showDeleteDialog(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          onDelete();
        }
      },
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            boxShadow: Theme.of(context).cardTheme.shadowColor != null 
                ? [BoxShadow(color: Theme.of(context).cardTheme.shadowColor!.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]
                : [],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Priority Indicator Stripe
                  Container(
                    width: 4,
                    color: priorityColor,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row: title + type badge
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).textTheme.bodyLarge?.color,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildTypeBadge(),
                            ],
                          ),
          
                          // Description
                          if (task.description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.description,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
          
                          const SizedBox(height: 12),
          
                          // Bottom row: date, category, priority, recurring
                          Row(
                            children: [
                              // Date & Time
                              Icon(
                                isOverdue ? Icons.warning_amber_rounded : Icons.access_time_rounded,
                                size: 14,
                                color: isOverdue ? AppTheme.error : Theme.of(context).textTheme.bodySmall?.color,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${dateFormat.format(task.dueDateTime)} • ${timeFormat.format(task.dueDateTime)}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: isOverdue ? AppTheme.error : Theme.of(context).textTheme.bodySmall?.color,
                                      fontWeight: isOverdue ? FontWeight.w600 : FontWeight.w400,
                                    ),
                              ),
                              const Spacer(),
                              // Category
                              _buildInfoChip(
                                context,
                                task.category,
                                Icons.label_outline,
                              ),
                              const SizedBox(width: 8),
                              // Recurring icon
                              if (task.recurringType != RecurringType.none) ...[
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypeBadge() {
    final isAlarm = task.taskType == TaskType.alarm;
    final gradient = isAlarm ? AppTheme.alarmGradient : AppTheme.reminderGradient;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isAlarm ? Icons.alarm : Icons.notifications_active_outlined,
            size: 12,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            isAlarm ? 'Alarm' : 'Reminder',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Theme.of(context).textTheme.bodySmall?.color),
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildSwipeBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    required String label,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
          ] else ...[
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 24),
          ],
        ],
      ),
    );
  }

  Future<bool?> _showDeleteDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to permanently delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
