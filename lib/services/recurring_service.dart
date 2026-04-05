import '../models/task.dart';
import '../database/database_helper.dart';

class RecurringService {
  static final RecurringService _instance = RecurringService._internal();
  factory RecurringService() => _instance;
  RecurringService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  /// Create the next occurrence of a recurring task after it's completed/deleted.
  /// Returns the new task's ID, or null if the task is not recurring.
  Future<int?> createNextOccurrence(Task completedTask) async {
    if (completedTask.recurringType == RecurringType.none) return null;

    final nextDueDate = _getNextDueDate(
      completedTask.dueDateTime,
      completedTask.recurringType,
    );

    final newTask = completedTask.copyWith(
      id: null,
      dueDateTime: nextDueDate,
      isCompleted: false,
      createdAt: DateTime.now(),
    );

    return await _dbHelper.insertTask(newTask);
  }

  DateTime _getNextDueDate(DateTime current, RecurringType type) {
    switch (type) {
      case RecurringType.daily:
        return current.add(const Duration(days: 1));
      case RecurringType.weekly:
        return current.add(const Duration(days: 7));
      case RecurringType.monthly:
        return DateTime(
          current.year,
          current.month + 1,
          current.day,
          current.hour,
          current.minute,
        );
      case RecurringType.yearly:
        return DateTime(
          current.year + 1,
          current.month,
          current.day,
          current.hour,
          current.minute,
        );
      case RecurringType.none:
        return current;
    }
  }
}
