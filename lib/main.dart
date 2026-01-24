import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:life_os/core/theme/app_theme.dart';
import 'package:life_os/features/lockscreen/pin_screen.dart';
import 'package:life_os/features/dashboard/dashboard_screen.dart';
import 'package:life_os/features/habits/habits_screen.dart';
import 'package:life_os/features/tasks/tasks_screen.dart';
import 'package:life_os/features/journal/journal_history_screen.dart';
import 'package:life_os/features/settings/settings_screen.dart';
import 'package:life_os/services/offline_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://wmmujtercgfbubjsuykv.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndtbXVqdGVyY2dmYnVianN1eWt2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMzI5MTAsImV4cCI6MjA4NDYwODkxMH0.RzMDmArP78LiUTJNPi-u3BH4IdfcLP6XKAsBJSttJ90',
  );

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize OfflineService
  final offlineService = OfflineService();
  await offlineService.init();

  // Sign in to Supabase once at startup
  final session = Supabase.instance.client.auth.currentSession;
  if (session == null) {
    await Supabase.instance.client.auth.signInAnonymously();
  }

  runApp(ProviderScope(
    overrides: [
      offlineServiceProvider.overrideWithValue(offlineService),
    ],
    child: const LifeOSApp(),
  ));
}

final _router = GoRouter(
  initialLocation: '/lock',
  routes: [
    GoRoute(
      path: '/lock',
      builder: (context, state) => const PinScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/habits',
      builder: (context, state) => const HabitsManagementScreen(),
    ),
    GoRoute(
      path: '/tasks',
      builder: (context, state) => const TaskManagementScreen(),
    ),
    GoRoute(
      path: '/journal',
      builder: (context, state) => const JournalHistoryScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);

class LifeOSApp extends ConsumerWidget {
  const LifeOSApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'LifeOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
