import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/task.dart';

class FilterBar extends StatelessWidget {
  final String? selectedCategory;
  final Priority? selectedPriority;
  final TaskType? selectedTaskType;
  final String sortBy;
  final bool sortAscending;
  final List<String> categories;
  final Function(String?) onCategoryChanged;
  final Function(Priority?) onPriorityChanged;
  final Function(TaskType?) onTaskTypeChanged;
  final Function(String) onSortChanged;
  final VoidCallback onSortDirectionToggle;
  final VoidCallback onClearFilters;
  final bool hasActiveFilters;

  const FilterBar({
    super.key,
    this.selectedCategory,
    this.selectedPriority,
    this.selectedTaskType,
    required this.sortBy,
    required this.sortAscending,
    required this.categories,
    required this.onCategoryChanged,
    required this.onPriorityChanged,
    required this.onTaskTypeChanged,
    required this.onSortChanged,
    required this.onSortDirectionToggle,
    required this.onClearFilters,
    required this.hasActiveFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chips row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Sort button
                _buildSortChip(context),
                const SizedBox(width: 8),

                // Category filter
                ..._buildCategoryChips(context),
                const SizedBox(width: 8),

                // Priority filter
                ..._buildPriorityChips(),
                const SizedBox(width: 8),

                // Task type filter
                _buildTypeChip('Alarm', TaskType.alarm, Icons.alarm, AppTheme.alarmColor),
                const SizedBox(width: 6),
                _buildTypeChip('Reminder', TaskType.reminder, Icons.notifications_active, AppTheme.reminderColor),

                // Clear filters
                if (hasActiveFilters) ...[
                  const SizedBox(width: 8),
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 16, color: AppTheme.error),
                    label: const Text('Clear'),
                    onPressed: onClearFilters,
                    backgroundColor: AppTheme.error.withOpacity(0.1),
                    side: BorderSide(color: AppTheme.error.withOpacity(0.3)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSortChip(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSortChanged,
      itemBuilder: (context) => [
        _buildSortMenuItem(context, 'date', 'Date', Icons.calendar_today),
        _buildSortMenuItem(context, 'priority', 'Priority', Icons.flag),
        _buildSortMenuItem(context, 'category', 'Category', Icons.label),
        _buildSortMenuItem(context, 'title', 'Title', Icons.sort_by_alpha),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'Sort: ${_getSortLabel(sortBy)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem(BuildContext context, String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: sortBy == value ? Theme.of(context).colorScheme.primary : Theme.of(context).textTheme.bodySmall?.color),
          const SizedBox(width: 8),
          Text(label),
          if (sortBy == value) ...[
            const Spacer(),
            IconButton(
              icon: Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              onPressed: onSortDirectionToggle,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildCategoryChips(BuildContext context) {
    return categories.map((cat) {
      final isSelected = selectedCategory == cat;
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(cat, style: TextStyle(fontSize: 11)),
          selected: isSelected,
          onSelected: (selected) {
            onCategoryChanged(selected ? cat : null);
          },
          selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
          checkmarkColor: Theme.of(context).colorScheme.primary,
          visualDensity: VisualDensity.compact,
        ),
      );
    }).toList();
  }

  List<Widget> _buildPriorityChips() {
    return [
      _buildPriorityChip('High', Priority.high, AppTheme.highPriority),
      const SizedBox(width: 6),
      _buildPriorityChip('Med', Priority.medium, AppTheme.mediumPriority),
      const SizedBox(width: 6),
      _buildPriorityChip('Low', Priority.low, AppTheme.lowPriority),
    ];
  }

  Widget _buildPriorityChip(String label, Priority priority, Color color) {
    final isSelected = selectedPriority == priority;
    return FilterChip(
      avatar: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        onPriorityChanged(selected ? priority : null);
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildTypeChip(String label, TaskType type, IconData icon, Color color) {
    final isSelected = selectedTaskType == type;
    return FilterChip(
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (selected) {
        onTaskTypeChanged(selected ? type : null);
      },
      selectedColor: color.withOpacity(0.2),
      checkmarkColor: color,
      visualDensity: VisualDensity.compact,
    );
  }

  String _getSortLabel(String sort) {
    switch (sort) {
      case 'date':
        return 'Date';
      case 'priority':
        return 'Priority';
      case 'category':
        return 'Category';
      case 'title':
        return 'Title';
      default:
        return 'Date';
    }
  }
}
