import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/widgets/daily_entry_card.dart';
import 'package:life_os/features/dashboard/widgets/today_habits_list.dart';
import 'package:life_os/features/dashboard/widgets/today_tasks_list.dart';
import 'package:life_os/features/dashboard/widgets/calendar_strip.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                const SizedBox(height: 16),
                
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

        return Row(
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
            
            // Compact Stats
            statsAsync.when(
              data: (stats) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        const Color(0xFFD97706).withValues(alpha: 0.2),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🔥', style: const TextStyle(fontSize: 20))
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(duration: 800.ms, begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
                          .then().shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${stats.streak}',
                            style: GoogleFonts.lexend(
                              fontWeight: FontWeight.w800, 
                              fontSize: 16, 
                              color: const Color(0xFFF59E0B),
                              height: 1.0,
                            ),
                          ),
                          Text(
                            'DAY STREAK',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              fontSize: 8,
                              color: const Color(0xFFD97706),
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              loading: () => const SizedBox.shrink(),
              error: (e, s) => const SizedBox.shrink(),
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


