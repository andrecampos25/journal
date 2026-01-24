import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/habits/habit_details_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/utils/contextual_messages.dart';
import 'package:life_os/core/widgets/swipeable_card.dart';
import 'package:confetti/confetti.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TodayHabitsList extends ConsumerStatefulWidget {
  const TodayHabitsList({super.key});

  @override
  ConsumerState<TodayHabitsList> createState() => _TodayHabitsListState();
}

class _TodayHabitsListState extends ConsumerState<TodayHabitsList> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(milliseconds: 800));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _playConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(selectedDateProvider);
    final habitsAsync = ref.watch(todayHabitsProvider(today));

    return Skeletonizer(
      enabled: habitsAsync.isLoading,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Habits',
                      style: GoogleFonts.lexend(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Icon(LucideIcons.checkCircle2, size: 18, color: Theme.of(context).colorScheme.secondary),
                  ],
                ),
                const SizedBox(height: 12),
                habitsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (habits) {
                    if (habits.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    
                    // Check if all habits are done
                    final allDone = habits.every((h) => h.isCompleted);
                    if (allDone) {
                      return _buildAllDoneState(context, habits.length);
                    }
                    
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
                      itemCount: habits.length,
                      separatorBuilder: (c, i) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final habit = habits[index];
                        final isDone = habit.isCompleted;

                        return SwipeableCard(
                          onSwipeRight: () async {
                            if (!isDone) _playConfetti();
                            await ref.read(todayHabitsProvider(today).notifier).toggleHabit(habit.id, !isDone);
                          },
                          rightLabel: isDone ? 'Undo' : 'Complete',
                          rightIcon: isDone ? Icons.undo : Icons.check_circle,
                          rightColor: isDone ? Colors.orange : Colors.green,
                          child: GestureDetector(
                            onTap: () async {
                              HapticFeedback.mediumImpact();
                              if (!isDone) _playConfetti();
                              await ref.read(todayHabitsProvider(today).notifier).toggleHabit(habit.id, !isDone);
                            },
                            child: AnimatedContainer(
                              duration: 300.ms,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? const Color(0xFF10B981).withValues(alpha: 0.1)
                                    : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.transparent,
                                ),
                              ),
                              child: Row(
                                children: [
                                  _buildCheckbox(isDone),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (c) => HabitDetailsScreen(habit: {
                                              'id': habit.id,
                                              'title': habit.title,
                                              'icon': habit.icon,
                                            }),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          Text(habit.icon, style: const TextStyle(fontSize: 18)),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: AnimatedDefaultTextStyle(
                                              duration: const Duration(milliseconds: 200),
                                              style: GoogleFonts.inter(
                                                fontSize: 14,
                                                fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                                                color: isDone
                                                    ? const Color(0xFF047857)
                                                    : Theme.of(context).colorScheme.onSurface,
                                                decoration: isDone ? TextDecoration.lineThrough : null,
                                                decorationColor: const Color(0xFF10B981),
                                              ),
                                              child: Text(
                                                habit.title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: Duration(milliseconds: 50 * index))
                            .slideX(begin: -0.1, end: 0, delay: Duration(milliseconds: 50 * index));
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckbox(bool isDone) {
    return AnimatedContainer(
      duration: 200.ms,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFF10B981) : Colors.transparent,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDone ? const Color(0xFF10B981) : Colors.grey.shade400,
          width: 1.5,
        ),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check, size: 16, color: Colors.white)
              .animate()
              .scale(
                begin: const Offset(0, 0),
                end: const Offset(1, 1),
                duration: 200.ms,
                curve: Curves.elasticOut,
              )
          : null,
    )
        .animate(target: isDone ? 1 : 0)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.15, 1.15),
          duration: 150.ms,
          curve: Curves.easeOut,
        )
        .then()
        .scale(
          begin: const Offset(1.15, 1.15),
          end: const Offset(1, 1),
          duration: 100.ms,
          curve: Curves.easeIn,
        );
  }

  Widget _buildEmptyState(BuildContext context) {
    final message = ContextualMessages.getHabitsEmptyMessage();
    final lines = message.split('\n');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF10B981).withValues(alpha: 0.05),
            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Text(
            lines[0],
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            lines.length > 1 ? lines[1] : '',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            ContextualMessages.getMotivationalQuote(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: const Color(0xFF10B981),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
  }

  Widget _buildAllDoneState(BuildContext context, int count) {
    final message = ContextualMessages.getAllHabitsDoneMessage();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981),
            Color(0xFF059669),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            '🎉',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '$count/$count habits complete',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn()
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
        .shimmer(delay: const Duration(milliseconds: 500), duration: const Duration(milliseconds: 1000));
  }
}
