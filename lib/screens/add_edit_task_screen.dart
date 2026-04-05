import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';

class AddEditTaskScreen extends StatefulWidget {
  final Task? task; // null for new task

  const AddEditTaskScreen({super.key, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _intervalController = TextEditingController();

  late Priority _priority;
  late DateTime _dueDate;
  late TimeOfDay _dueTime;
  late String _category;
  late TaskType _taskType;
  late RecurringType _recurringType;
  bool _isSaving = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  bool get isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(parent: _animController, curve: Curves.easeOut);

    if (isEditing) {
      final t = widget.task!;
      _titleController.text = t.title;
      _descriptionController.text = t.description;
      _priority = t.priority;
      _dueDate = t.dueDateTime;
      _dueTime = TimeOfDay.fromDateTime(t.dueDateTime);
      _category = t.category;
      _taskType = t.taskType;
      _recurringType = t.recurringType;
      _intervalController.text = t.reminderIntervalMinutes.toString();
    } else {
      _priority = Priority.medium;
      _dueDate = DateTime.now().add(const Duration(hours: 1));
      _dueTime = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));
      _category = 'General';
      _taskType = TaskType.alarm;
      _recurringType = RecurringType.none;
      _intervalController.text = '5';
    }

    _animController.forward();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _intervalController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _saveTask,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 18),
              label: Text(isEditing ? 'Update' : 'Save'),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title field
                _buildSectionLabel('Title *'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Enter task title...',
                    prefixIcon: Icon(Icons.title_rounded, color: Theme.of(context).colorScheme.primary),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Description field
                _buildSectionLabel('Description'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Optional description...',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(bottom: 48),
                      child: Icon(Icons.description_outlined, color: Theme.of(context).textTheme.bodySmall?.color),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Task Type selector (Alarm / Reminder)
                _buildSectionLabel('Task Type'),
                const SizedBox(height: 8),
                _buildTaskTypeSelector(),

                // Reminder interval (only shown for reminder type)
                if (_taskType == TaskType.reminder) ...[
                  const SizedBox(height: 16),
                  _buildReminderIntervalField(),
                ],

                const SizedBox(height: 24),

                // Due Date & Time
                _buildSectionLabel('Due Date & Time'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _buildDatePicker()),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTimePicker()),
                  ],
                ),

                const SizedBox(height: 24),

                // Priority selector
                _buildSectionLabel('Priority'),
                const SizedBox(height: 8),
                _buildPrioritySelector(),

                const SizedBox(height: 24),

                // Category selector
                _buildSectionLabel('Category'),
                const SizedBox(height: 8),
                _buildCategorySelector(),

                const SizedBox(height: 24),

                // Recurring selector
                _buildSectionLabel('Recurring'),
                const SizedBox(height: 8),
                _buildRecurringSelector(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTaskTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            'Alarm',
            Icons.alarm,
            TaskType.alarm,
            AppTheme.alarmGradient,
            AppTheme.alarmColor,
            'Sound + notification\nat exact time',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            'Reminder',
            Icons.notifications_active,
            TaskType.reminder,
            AppTheme.reminderGradient,
            AppTheme.reminderColor,
            'Repeat every N min\nuntil done',
          ),
        ),
      ],
    );
  }

  Widget _buildTypeOption(String label, IconData icon, TaskType type,
      LinearGradient gradient, Color color, String subtitle) {
    final isSelected = _taskType == type;
    return GestureDetector(
      onTap: () => setState(() => _taskType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: isSelected ? color : Theme.of(context).dividerColor.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 28, color: isSelected ? Colors.white : AppTheme.textMuted),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white70 : AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderIntervalField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppTheme.reminderColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_outlined, color: AppTheme.reminderColor, size: 22),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Repeat every',
              style: TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(
            width: 60,
            child: TextFormField(
              controller: _intervalController,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                color: AppTheme.reminderColor,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.reminderColor.withOpacity(0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppTheme.reminderColor.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: AppTheme.bgSurface,
              ),
              validator: (value) {
                if (_taskType == TaskType.reminder) {
                  if (value == null || value.isEmpty) return 'Required';
                  final mins = int.tryParse(value);
                  if (mins == null || mins < 1) return 'Min 1';
                }
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'minutes',
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker() {
    final dateStr = DateFormat('MMM dd, yyyy').format(_dueDate);
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(dateStr, style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker() {
    final timeStr = _dueTime.format(context);
    return GestureDetector(
      onTap: _pickTime,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(color: AppTheme.bgCardLight),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Text(timeStr, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: Priority.values.map((p) {
        final isSelected = _priority == p;
        final color = AppTheme.getPriorityColor(p.index);
        final label = p == Priority.high ? 'High' : (p == Priority.medium ? 'Medium' : 'Low');
        final icon = p == Priority.high
            ? Icons.keyboard_double_arrow_up_rounded
            : (p == Priority.medium
                ? Icons.remove_rounded
                : Icons.keyboard_double_arrow_down_rounded);

        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _priority = p),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(right: p != Priority.low ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isSelected ? color : Theme.of(context).dividerColor.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(icon, color: isSelected ? color : AppTheme.textMuted, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? color : AppTheme.textSecondary,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector() {
    return Consumer<CategoryProvider>(
      builder: (context, provider, _) {
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: provider.categories.map((cat) {
            final isSelected = _category == cat.name;
            return GestureDetector(
              onTap: () => setState(() => _category = cat.name),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? cat.color.withOpacity(0.15) : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? cat.color : Theme.of(context).dividerColor.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 16, color: isSelected ? cat.color : AppTheme.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      cat.name,
                      style: TextStyle(
                        color: isSelected ? cat.color : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRecurringSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: RecurringType.values.map((r) {
          final isSelected = _recurringType == r;
          final label = r == RecurringType.none
              ? 'One-time'
              : r.name[0].toUpperCase() + r.name.substring(1);
          final icon = r == RecurringType.none
              ? Icons.looks_one_rounded
              : Icons.repeat_rounded;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _recurringType = r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentColor.withOpacity(0.15)
                      : Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.accentColor : Theme.of(context).dividerColor.withOpacity(0.1),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? AppTheme.accentColor : AppTheme.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppTheme.accentColor : Theme.of(context).textTheme.bodyMedium?.color,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dueTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dueTime = picked);
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final dueDateTime = DateTime(
      _dueDate.year,
      _dueDate.month,
      _dueDate.day,
      _dueTime.hour,
      _dueTime.minute,
    );

    final interval = int.tryParse(_intervalController.text) ?? 5;

    final task = Task(
      id: widget.task?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      priority: _priority,
      dueDateTime: dueDateTime,
      category: _category,
      taskType: _taskType,
      reminderIntervalMinutes: interval,
      recurringType: _recurringType,
      createdAt: widget.task?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<TaskProvider>();

    try {
      if (isEditing) {
        await provider.updateTask(task);
      } else {
        await provider.addTask(task);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
