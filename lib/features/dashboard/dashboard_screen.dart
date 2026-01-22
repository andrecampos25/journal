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
            ).animate(onPlay: (controller) => controller.repeat(reverse: true))
             .scale(duration: 5.seconds, begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), curve: Curves.easeInOut)
             .moveX(duration: 8.seconds, begin: -20, end: 20, curve: Curves.easeInOut),
          ),
          Positioned(
            bottom: -50,
            left: -50,
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
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gamification Stats
                        const _StatsRow(),
                        const SizedBox(height: 24),
                        
                        // Tasks & Habits Combined Card
                        Container(
                           decoration: BoxDecoration(
                             color: Theme.of(context).cardColor.withValues(alpha: 0.5),
                             borderRadius: BorderRadius.circular(24),
                             border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                           ),
                           child: Column(
                             children: [
                               const TodayTasksList(),
                               Divider(color: Colors.grey.withValues(alpha: 0.1), height: 1),
                               const TodayHabitsList(),
                             ],
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
              ],
            ),
          ),
          
          // Fixed Navigation Bar
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: _buildNavigationCard(context),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hour = DateTime.now().hour;
    String greeting;
    String subtext;
    
    if (hour < 12) {
      greeting = 'Good Morning,';
      subtext = 'Ready to seize the day?';
    } else if (hour < 18) {
      greeting = 'Good Afternoon,';
      subtext = 'Keeping the momentum?';
    } else {
      greeting = 'Good Evening,';
      subtext = 'Time to wind down.';
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            Text(
              subtext,
              style: GoogleFonts.inter(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/settings');
          },
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.settings, size: 20, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationCard(BuildContext context) {
     return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
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
      child: Icon(icon, color: const Color(0xFF1E293B), size: 26),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    
    return IntrinsicHeight( // Ensures equal height
      child: statsAsync.when(
        data: (stats) => Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _StatChip(
                icon: LucideIcons.flame,
                label: '${stats.streak} Streak',
                color: const Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatChip(
                icon: LucideIcons.trophy,
                label: 'Lvl ${stats.level} • ${stats.totalXp} XP',
                color: const Color(0xFF6366F1),
                progress: stats.currentLevelProgress,
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(height: 48),
        error: (e, s) => const SizedBox(),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double? progress;

  const _StatChip({required this.icon, required this.label, required this.color, this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Solid card color for better read
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
             const SizedBox(height: 8),
             ClipRRect(
               borderRadius: BorderRadius.circular(4),
               child: LinearProgressIndicator(
                 value: progress,
                 minHeight: 6,
                 backgroundColor: color.withValues(alpha: 0.1),
                 valueColor: AlwaysStoppedAnimation(color),
               ),
             ),
          ] else ...[
             // Spacer to match the height if progress is missing? 
             // IntrinsicHeight handles the container height matching, 
             // but contents might not be vertically centered if one has extra widget.
             // Adding transparent spacer or ensuring alignment helps.
             const SizedBox(height: 14), // Approx height of progress bar + padding
          ]
        ],
      ),
    );
  }
}


