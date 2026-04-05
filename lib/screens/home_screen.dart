import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';
import '../providers/category_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/task_card.dart';
import '../widgets/filter_bar.dart';
import 'add_edit_task_screen.dart';
import 'task_detail_screen.dart';
import 'categories_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabAnimation = CurvedAnimation(parent: _fabController, curve: Curves.elasticOut);

    // Load data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TaskProvider>().loadTasks();
      context.read<CategoryProvider>().loadCategories();
      _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildStatsRow(),
            _buildFilterBar(),
            Expanded(child: _buildTaskList()),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: FloatingActionButton.extended(
          heroTag: 'home_fab',
          onPressed: _navigateToAddTask,
          icon: const Icon(Icons.add_rounded, size: 24),
          label: const Text('Add Task'),
          elevation: 8,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final now = DateTime.now();
    final dateStr = DateFormat('EEEE, MMM dd').format(now);
    final greeting = _getGreeting(now.hour);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Text(
                      'NovaTask',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ],
                ),
                Text(
                  dateStr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Categories button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: IconButton(
              onPressed: _navigateToCategories,
              icon: Icon(Icons.category_rounded, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
          ),
          const SizedBox(width: 8),
          // Settings button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: IconButton(
              onPressed: _navigateToSettings,
              icon: Icon(Icons.settings_rounded, color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7)),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
  }

  Widget _buildStatsRow() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Row(
            children: [
              _buildStatCard(
                'Total',
                '${provider.totalTasks}',
                Icons.task_alt_rounded,
                AppTheme.primaryGradient,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Alarms',
                '${provider.alarmCount}',
                Icons.alarm,
                AppTheme.alarmGradient,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Reminders',
                '${provider.reminderCount}',
                Icons.notifications_active,
                AppTheme.reminderGradient,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Urgent',
                '${provider.highPriorityCount}',
                Icons.priority_high_rounded,
                const LinearGradient(
                  colors: [Color(0xFFFF4757), Color(0xFFFF6B81)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, LinearGradient gradient) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: Colors.white.withOpacity(0.9)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Consumer2<TaskProvider, CategoryProvider>(
      builder: (context, taskProvider, categoryProvider, _) {
        return FilterBar(
          selectedCategory: taskProvider.filterCategory,
          selectedPriority: taskProvider.filterPriority,
          selectedTaskType: taskProvider.filterTaskType,
          sortBy: taskProvider.sortBy,
          sortAscending: taskProvider.sortAscending,
          categories: categoryProvider.categoryNames,
          hasActiveFilters: taskProvider.hasActiveFilters,
          onCategoryChanged: (cat) {
            taskProvider.setFilter(
              category: cat,
              priority: taskProvider.filterPriority,
              taskType: taskProvider.filterTaskType,
            );
          },
          onPriorityChanged: (p) {
            taskProvider.setFilter(
              category: taskProvider.filterCategory,
              priority: p,
              taskType: taskProvider.filterTaskType,
            );
          },
          onTaskTypeChanged: (t) {
            taskProvider.setFilter(
              category: taskProvider.filterCategory,
              priority: taskProvider.filterPriority,
              taskType: t,
            );
          },
          onSortChanged: (sort) {
            taskProvider.setSort(sort);
          },
          onSortDirectionToggle: () {
            taskProvider.toggleSortDirection();
          },
          onClearFilters: () {
            taskProvider.clearFilters();
          },
        );
      },
    );
  }

  Widget _buildTaskList() {
    return Consumer<TaskProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return Center(
            child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
          );
        }

        if (provider.tasks.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 100),
          itemCount: provider.tasks.length,
          itemBuilder: (context, index) {
            final task = provider.tasks[index];
            return TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (index * 50)),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: TaskCard(
                task: task,
                onTap: () => _navigateToDetail(task),
                onComplete: () => _completeTask(task),
                onDelete: () => _deleteTask(task),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.task_alt_rounded,
              size: 64,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Tasks Yet',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the + button to create your first task\nwith an alarm or reminder',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  String _getGreeting(int hour) {
    if (hour < 12) return '☀️ Good Morning';
    if (hour < 17) return '🌤️ Good Afternoon';
    return '🌙 Good Evening';
  }

  void _navigateToAddTask() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddEditTaskScreen(),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _navigateToDetail(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  void _navigateToCategories() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoriesScreen()),
    );
  }

  void _completeTask(Task task) async {
    await context.read<TaskProvider>().completeTask(task);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: AppTheme.success, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.recurringType != RecurringType.none
                      ? '"${task.title}" completed! Next occurrence created.'
                      : '"${task.title}" completed & deleted!',
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _deleteTask(Task task) async {
    await context.read<TaskProvider>().deleteTask(task.id!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.delete, color: AppTheme.error, size: 20),
              const SizedBox(width: 8),
              Text('"${task.title}" deleted permanently'),
            ],
          ),
        ),
      );
    }
  }
}
