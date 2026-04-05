import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/routine_provider.dart';
import '../theme/app_theme.dart';

class RoutineReportScreen extends StatefulWidget {
  const RoutineReportScreen({super.key});

  @override
  State<RoutineReportScreen> createState() => _RoutineReportScreenState();
}

class _RoutineReportScreenState extends State<RoutineReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Productivity Report'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
            Tab(text: 'This Month'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildReportView(context, 'today'),
          _buildReportView(context, 'week'),
          _buildReportView(context, 'month'),
        ],
      ),
    );
  }

  Widget _buildReportView(BuildContext context, String period) {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = now;

    if (period == 'today') {
      start = DateTime(now.year, now.month, now.day);
    } else if (period == 'week') {
      start = now.subtract(Duration(days: now.weekday - 1));
      start = DateTime(start.year, start.month, start.day);
    } else {
      start = DateTime(now.year, now.month, 1);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: context.read<RoutineProvider>().getCompletionStats(start, end),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final stats = snapshot.data ?? {'totalCompleted': 0, 'byGroup': <String, int>{}, 'logCount': 0};
        final totalCompleted = stats['totalCompleted'] as int;
        final byGroup = stats['byGroup'] as Map<String, int>;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCard(context, period, totalCompleted),
              const SizedBox(height: 24),
              Text(
                'Performance Details',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (byGroup.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('No completed tasks in this period.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ...byGroup.entries.map((entry) => _buildGroupRow(context, entry.key, entry.value)),
              const SizedBox(height: 24),
              _buildTipCard(context, totalCompleted),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupRow(BuildContext context, String groupTitle, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(groupTitle, style: const TextStyle(fontWeight: FontWeight.w500)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count Done',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String period, int completed) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Total Tasks Completed',
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            completed.toString(),
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getPeriodLabel(period),
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context, int completed) {
    String message = completed > 0 
      ? "Great job! Keep up the momentum." 
      : "Start small. Complete one task today to build your streak.";
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: AppTheme.accentColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  String _getPeriodLabel(String period) {
    if (period == 'today') return 'Since 12:00 AM';
    if (period == 'week') return 'This Week';
    return 'This Month';
  }
}
