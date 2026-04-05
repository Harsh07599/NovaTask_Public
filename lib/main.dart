import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme/app_theme.dart';
import 'providers/task_provider.dart';
import 'providers/category_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/routine_provider.dart';
import 'providers/note_provider.dart';
import 'services/notification_service.dart';
import 'services/alarm_service.dart';
import 'services/sync_service.dart';
import 'screens/main_navigation_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Sign in anonymously to enable Firestore sync
  try {
    final userCredential = await FirebaseAuth.instance.signInAnonymously();
    debugPrint('[Auth] Signed in anonymously: ${userCredential.user?.uid}');
  } catch (e) {
    debugPrint('[Auth] Failed to sign in anonymously: $e');
  }

  // Initial system UI style handled in NovaTaskApp build

  // Initialize notification service (with timezone fix)
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Initialize android_alarm_manager_plus for background alarms
  await AlarmService.initialize();

  // Initialize and load settings
  final settingsProvider = SettingsProvider();
  await settingsProvider.loadSettings();
  
  // Initialize and load routines
  final routineProvider = RoutineProvider();
  await routineProvider.loadRoutines();

  // Initialize and load notes
  final noteProvider = NoteProvider();
  await noteProvider.loadNotes();

  // Run initial sync (fire and forget)
  SyncService().syncAll();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider.value(value: routineProvider),
        ChangeNotifierProvider.value(value: noteProvider),
        ChangeNotifierProvider(create: (_) => SyncService()),
      ],
      child: const NovaTaskApp(),
    ),
  );
}

class NovaTaskApp extends StatelessWidget {
  const NovaTaskApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = Provider.of<SettingsProvider>(context);
    final isDark = settingsProvider.themeMode == ThemeMode.dark;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarColor: isDark ? AppTheme.bgDark : const Color(0xFFF8FAFC),
      systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));
    
    return MaterialApp(
      title: 'NovaTask',
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: settingsProvider.themeMode,
      home: const MainNavigationScreen(),
    );
  }
}
