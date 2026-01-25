import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';

class DailyProgressIndicator extends ConsumerWidget {
  const DailyProgressIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(todayTasksProvider(today));
    final habitsAsync = ref.watch(todayHabitsProvider(today));

    return tasksAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (tasks) {
        return habitsAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
          data: (habits) {
            // Calculate progress
            final totalTasks = tasks.length;
            final completedTasks = tasks.where((t) => t.isCompleted).length;
            final totalHabits = habits.length;
            final completedHabits = habits.where((h) => h.isCompleted).length;
            
            final totalItems = totalTasks + totalHabits;
            final completedItems = completedTasks + completedHabits;
            
            if (totalItems == 0) return const SizedBox.shrink();
            
            final progress = completedItems / totalItems;
            final percentage = (progress * 100).toInt();

            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: progress == 1.0
                        ? [
                            const Color(0xFF10B981).withValues(alpha: 0.1),
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          ]
                        : [
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                            Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: progress == 1.0
                        ? const Color(0xFF10B981).withValues(alpha: 0.3)
                        : Theme.of(context).dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Progress',
                          style: GoogleFonts.lexend(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (progress == 1.0)
                          const Text('🎉', style: TextStyle(fontSize: 20))
                              .animate()
                              .scale(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.elasticOut,
                              )
                        else
                          Text(
                            '$percentage%',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        height: 8,
                        child: Stack(
                          children: [
                            // Background
                            Container(
                              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
                            ),
                            // Progress
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: progress == 1.0
                                        ? [
                                            const Color(0xFF10B981),
                                            const Color(0xFF059669),
                                          ]
                                        : [
                                            Theme.of(context).colorScheme.primary,
                                            Theme.of(context).colorScheme.secondary,
                                          ],
                                  ),
                                ),
                              ),
                            )
                                .animate()
                                .scaleX(
                                  duration: const Duration(milliseconds: 800),
                                  curve: Curves.easeOutCubic,
                                  alignment: Alignment.centerLeft,
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Stats row
                    Row(
                      children: [
                        _buildStat(
                          context,
                          icon: '✓',
                          label: 'Tasks',
                          value: '$completedTasks/$totalTasks',
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 16),
                        _buildStat(
                          context,
                          icon: '⚡',
                          label: 'Habits',
                          value: '$completedHabits/$totalHabits',
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(
                  delay: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                )
                .slideY(
                  begin: -0.1,
                  end: 0,
                  delay: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
          },
        );
      },
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Row(
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
