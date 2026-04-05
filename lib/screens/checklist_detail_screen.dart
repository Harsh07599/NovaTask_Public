import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../models/routine.dart';
import '../models/task.dart';
import '../theme/app_theme.dart';

class ChecklistDetailScreen extends StatefulWidget {
  final RoutineGroup group;

  const ChecklistDetailScreen({super.key, required this.group});

  @override
  State<ChecklistDetailScreen> createState() => _ChecklistDetailScreenState();
}

class _ChecklistDetailScreenState extends State<ChecklistDetailScreen> {
  final TextEditingController _itemController = TextEditingController();

  @override
  void dispose() {
    _itemController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => _showEditGroupDialog(context),
            tooltip: 'Edit Group',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.error),
            onPressed: () => _confirmDeleteGroup(context),
            tooltip: 'Delete Group',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildAddItemInput(context),
          const Divider(height: 1),
          Expanded(child: _buildItemList(context)),
        ],
      ),
    );
  }

  Widget _buildAddItemInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _itemController,
              decoration: const InputDecoration(
                hintText: 'Add new item...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => _addItem(context),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: () => _addItem(context),
            icon: const Icon(Icons.add_rounded),
            style: IconButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.secondary),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Pre-fetch items when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().getItems(widget.group.id!);
    });
  }

  Widget _buildItemList(BuildContext context) {
    return Consumer<RoutineProvider>(
      builder: (context, provider, _) {
        final items = provider.getItemsCached(widget.group.id!);
        final isLoading = provider.isItemsLoading(widget.group.id!);
        
        if (items.isEmpty && isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No items yet. Add one above!',
              style: TextStyle(color: AppTheme.textMuted),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _buildItemTile(context, item, provider);
          },
        );
      },
    );
  }

  Widget _buildItemTile(BuildContext context, RoutineItem item, RoutineProvider provider) {
    return ListTile(
      leading: Checkbox(
        value: item.isCompleted,
        onChanged: (_) => provider.toggleItem(item),
        activeColor: Theme.of(context).colorScheme.secondary,
      ),
      title: Text(
        item.title,
        style: TextStyle(
          decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          color: item.isCompleted ? Theme.of(context).textTheme.bodySmall?.color : Theme.of(context).textTheme.bodyLarge?.color,
          fontSize: 16,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.textMuted),
        onPressed: () => provider.deleteItem(item),
      ),
    );
  }

  void _addItem(BuildContext context) {
    if (_itemController.text.isNotEmpty) {
      context.read<RoutineProvider>().addItem(widget.group.id!, _itemController.text);
      _itemController.clear();
    }
  }

  void _showEditGroupDialog(BuildContext context) {
    final titleController = TextEditingController(text: widget.group.title);
    RecurringType selectedFreq = widget.group.frequency;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Checklist Group'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Group Title'),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<RecurringType>(
                value: selectedFreq,
                decoration: const InputDecoration(labelText: 'Reset Frequency'),
                items: RecurringType.values
                    .where((f) => f != RecurringType.none)
                    .map((f) => DropdownMenuItem(value: f, child: Text(f.name.toUpperCase())))
                    .toList(),
                onChanged: (val) => setState(() => selectedFreq = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final updatedGroup = widget.group.copyWith(
                    title: titleController.text,
                    frequency: selectedFreq,
                  );
                  await context.read<RoutineProvider>().updateGroup(updatedGroup);
                  if (mounted) Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Checklist?'),
        content: const Text('This will delete the entire group and all its items.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<RoutineProvider>().deleteGroup(widget.group.id!);
              Navigator.pop(context); // Dialog
              Navigator.pop(context); // Screen
            },
            child: const Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }
}
