import 'dart:ui';
import 'package:flutter/material.dart';
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
            ),
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
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 16),
                  _buildHeader(),
                  const SizedBox(height: 24),
                  
                  // Calendar Strip
                  const CalendarStrip(),
                  const SizedBox(height: 16),
                  
                  // Gamification Stats
                  const _StatsRow(),
                  const SizedBox(height: 24),
                  
                  // Bento Grid
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: StaggeredGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        children: [
                          // 1. Daily Entry (Full Width)
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: 280, // Increased height for journal
                            child: const DailyEntryCard(),
                          ),
                          
                          // 2. Habits (Left Column)
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 1,
                            mainAxisExtent: 220,
                            child: const TodayHabitsList(),
                          ),
                          
                          // 3. Tasks (Right Column - Taller)
                          StaggeredGridTile.extent(
                            crossAxisCellCount: 1,
                            mainAxisExtent: 220,
                            child: const TodayTasksList(),
                          ),
                          
                           // 4. Quick Actions / Navigation (Bottom Strip)
                           StaggeredGridTile.extent(
                            crossAxisCellCount: 2,
                            mainAxisExtent: 80,
                            child: _buildNavigationCard(context),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Good Morning,',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            Text(
              'Ready to seize the day?',
              style: GoogleFonts.inter(
                fontSize: 14, 
                color: Theme.of(context).colorScheme.secondary,
              ),
            ),
          ],
        ),
        // Removed static pill, stats are now below
        IconButton(
          onPressed: () => context.push('/settings'),
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
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(onPressed: () => context.push('/journal'), icon: const Icon(Icons.history_rounded, color: Color(0xFF1E293B))),
              IconButton(onPressed: () => context.push('/habits'), icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF1E293B))),
              IconButton(onPressed: () => context.push('/tasks'), icon: const Icon(Icons.list_alt_rounded, color: Color(0xFF1E293B))),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends ConsumerWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    
    return statsAsync.when(
      data: (stats) => Row(
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
      loading: () => const SizedBox(height: 48), // placeholder
      error: (e, s) => const SizedBox(),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
             const SizedBox(height: 6),
             ClipRRect(
               borderRadius: BorderRadius.circular(2),
               child: LinearProgressIndicator(
                 value: progress,
                 minHeight: 4,
                 backgroundColor: color.withValues(alpha: 0.1),
                 valueColor: AlwaysStoppedAnimation(color),
               ),
             ),
          ]
        ],
      ),
    );
  }
}


