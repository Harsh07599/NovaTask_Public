import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../models/routine.dart';
import '../models/task.dart'; // For RecurringType
import '../theme/app_theme.dart';
import 'checklist_detail_screen.dart';
import 'routine_report_screen.dart';

class ChecklistScreen extends StatelessWidget {
  const ChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildGroupList(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'checklist_fab',
        onPressed: () => _showAddGroupDialog(context),
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('New Checklist'),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Checklists',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              IconButton.filledTonal(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RoutineReportScreen()),
                ),
                icon: const Icon(Icons.analytics_rounded),
                tooltip: 'Productivity Report',
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Groups of tasks that reset at midnight',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(BuildContext context) {
    return Consumer<RoutineProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary));
        }

        if (provider.groups.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist_rounded, size: 64, color: AppTheme.textMuted.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No checklists created yet',
                  style: TextStyle(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: provider.groups.length,
          itemBuilder: (context, index) {
            final group = provider.groups[index];
            return _buildGroupCard(context, group);
          },
        );
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, RoutineGroup group) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ChecklistDetailScreen(group: group)),
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Consumer<RoutineProvider>(
          builder: (context, provider, _) {
            final counts = provider.getCounts(group.id!);
            final completed = counts['completed'] ?? 0;
            final total = counts['total'] ?? 0;
            final isAllCompleted = completed == total && total > 0;

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                border: Border.all(
                  color: isAllCompleted ? AppTheme.accentColor.withOpacity(0.5) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (isAllCompleted ? AppTheme.accentColor : Theme.of(context).colorScheme.primary).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isAllCompleted ? Icons.check_circle_rounded : Icons.list_alt_rounded, 
                      color: isAllCompleted ? AppTheme.accentColor : Theme.of(context).colorScheme.primary, 
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.title,
                          style: TextStyle(
                            fontSize: 18, 
                            fontWeight: FontWeight.bold, 
                            color: isAllCompleted ? Theme.of(context).colorScheme.secondary : Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Resets ${group.frequency.name}',
                              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                            ),
                            const SizedBox(width: 8),
                            const Text('•', style: TextStyle(color: AppTheme.textMuted)),
                            const SizedBox(width: 8),
                            Text(
                              '$completed/$total tasks',
                              style: TextStyle(
                                fontSize: 12, 
                                color: isAllCompleted ? AppTheme.accentColor : AppTheme.textMuted,
                                fontWeight: isAllCompleted ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded, 
                    color: isAllCompleted ? AppTheme.accentColor.withOpacity(0.5) : AppTheme.textMuted,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _showAddGroupDialog(BuildContext context) {
    final titleController = TextEditingController();
    RecurringType selectedFreq = RecurringType.daily;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Checklist Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Group Title',
                  hintText: 'e.g., Morning Routine',
                  labelStyle: TextStyle(color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<RecurringType>(
                value: selectedFreq,
                decoration: const InputDecoration(labelText: 'Reset Frequency'),
                items: RecurringType.values.where((f) => f != RecurringType.none).map((f) {
                  return DropdownMenuItem(value: f, child: Text(f.name.toUpperCase()));
                }).toList(),
                onChanged: (val) => setState(() => selectedFreq = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty) {
                  context.read<RoutineProvider>().addGroup(titleController.text, selectedFreq);
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
