import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/widgets/daily_entry_card.dart';
import 'package:life_os/features/dashboard/widgets/today_habits_list.dart';
import 'package:life_os/features/dashboard/widgets/today_tasks_list.dart';
import 'package:life_os/features/dashboard/widgets/calendar_strip.dart';
import 'package:life_os/features/dashboard/widgets/daily_progress_indicator.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/utils/quotes_logic.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app comes to foreground
      final date = ref.read(selectedDateProvider);
      ref.invalidate(todayHabitsProvider(date));
      // Refreshing the notifier directly if possible, or just invalidate
      ref.read(todayHabitsProvider(date).notifier).refresh();
      ref.read(todayTasksProvider(date).notifier).refresh();
      ref.invalidate(userStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Glassmorphism background gradient
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Ambient Background Blobs
          Positioned(
            top: -100,
            right: -100,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blue.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withValues(alpha: 0.3),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), curve: Curves.easeInOut)
             .moveX(duration: 8.seconds, begin: -20, end: 20, curve: Curves.easeInOut),
          ),
          
          Positioned(
            bottom: -50,
            left: -50,
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.purple.withValues(alpha: 0.1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.3),
                      blurRadius: 100,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 7.seconds, begin: const Offset(1.2, 1.2), end: const Offset(0.9, 0.9), curve: Curves.easeInOut)
             .moveY(duration: 10.seconds, begin: -30, end: 30, curve: Curves.easeInOut),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildHeader(context),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                
                // Calendar Strip (Full width)
                const CalendarStrip(),
                const SizedBox(height: 8),
                
                // Daily Progress Indicator
                const DailyProgressIndicator(),
                const SizedBox(height: 8),
                
                // Scrollable Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      final date = ref.read(selectedDateProvider);
                      // Force network refresh via notifier methods
                      await Future.wait([
                        ref.read(todayTasksProvider(date).notifier).refresh(),
                        ref.read(todayHabitsProvider(date).notifier).refresh(),
                        ref.refresh(userStatsProvider.future),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(), // Ensure it can always scroll for refresh
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Tasks & Habits Combined Card
                          Container(
                             decoration: BoxDecoration(
                               borderRadius: BorderRadius.circular(32),
                               boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.black.withValues(alpha: 0.3) 
                                        : const Color(0xFF94A3B8).withValues(alpha: 0.15),
                                    blurRadius: 24,
                                    offset: const Offset(0, 8),
                                  ),
                               ],
                             ),
                             child: ClipRRect(
                               borderRadius: BorderRadius.circular(32),
                               child: BackdropFilter(
                                 filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                 child: Container(
                                   decoration: BoxDecoration(
                                     color: Theme.of(context).brightness == Brightness.dark 
                                         ? const Color(0xFF1E293B).withValues(alpha: 0.5) 
                                         : Colors.white.withValues(alpha: 0.4),
                                     borderRadius: BorderRadius.circular(32),
                                     border: Border.all(
                                       color: Theme.of(context).brightness == Brightness.dark 
                                           ? Colors.white.withValues(alpha: 0.1) 
                                           : Colors.white.withValues(alpha: 0.4),
                                     ),
                                   ),
                                   child: Column(
                                     children: [
                                       const TodayTasksList(),
                                       Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                                       const TodayHabitsList(),
                                     ],
                                   ),
                                 ),
                               ),
                             ),
                          ),
  
                          const SizedBox(height: 24),
  
                          // Daily Entry
                          const SizedBox(
                            height: 300,
                            child: DailyEntryCard(),
                          ),
                          
                          // Spacer for fixed nav bar
                          const SizedBox(height: 100),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Fixed Navigation Bar
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildNavigationCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final statsAsync = ref.watch(userStatsProvider);
        final hour = DateTime.now().hour;
        String greeting;
        if (hour < 12) {
          greeting = 'Good Morning';
        } else if (hour < 18) {
          greeting = 'Good Afternoon';
        } else {
          greeting = 'Good Evening';
        }

        final quote = QuotesLogic.getDailyQuote();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  greeting,
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                
                // Minimalist Streak
                statsAsync.when(
                  data: (stats) => Row(
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 4),
                      Text(
                        '${stats.streak}',
                        style: GoogleFonts.lexend(
                          fontWeight: FontWeight.w600, 
                          fontSize: 18, 
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (e, s) => const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '"${quote['text']}"',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNavigationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark 
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark 
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : const Color(0xFF94A3B8).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _NavButton(icon: LucideIcons.history, label: 'Journal', onTap: () => context.push('/journal')),
                _NavButton(icon: LucideIcons.checkCircle, label: 'Habits', onTap: () => context.push('/habits')),
                _NavButton(icon: LucideIcons.listTodo, label: 'Tasks', onTap: () => context.push('/tasks')),
                _NavButton(icon: LucideIcons.settings, label: 'Settings', onTap: () => context.push('/settings')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NavButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 26),
    );
  }
}


