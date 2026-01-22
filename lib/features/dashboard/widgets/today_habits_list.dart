import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/habits/habit_details_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
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
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Center(child: Text('No habits set', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))),
                      );
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
                        
                        return GestureDetector(
                            onTap: () async {
                               HapticFeedback.lightImpact();
                               if (!isDone) _playConfetti(); // Celebrate completion
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
                               GestureDetector(
                                onTap: () async {
                                   HapticFeedback.mediumImpact(); // Stronger haptic
                                   if (!isDone) _playConfetti(); 
                                   await ref.read(todayHabitsProvider(today).notifier).toggleHabit(habit.id, !isDone);
                                },
                                 child: AnimatedContainer(
                                  duration: 200.ms,
                                  width: 24,
                                  height: 24,
                                   decoration: BoxDecoration(
                                    color: isDone ? const Color(0xFF10B981) : Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: isDone ? const Color(0xFF10B981) : Theme.of(context).dividerColor,
                                      width: 1.5,
                                    ),
                                    boxShadow: isDone ? [
                                      BoxShadow(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ] : null,
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
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                     Navigator.push(context, MaterialPageRoute(builder: (c) => HabitDetailsScreen(habit: {
                                       'id': habit.id,
                                       'title': habit.title,
                                       'icon': habit.icon,
                                     })));
                                  },
                                  child: Row(
                                    children: [
                                      Text(habit.icon, style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          habit.title,
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                                            color: isDone 
                                                ? const Color(0xFF047857) 
                                                : Theme.of(context).colorScheme.onSurface,
                                            decoration: isDone ? TextDecoration.lineThrough : null,
                                            decorationColor: const Color(0xFF10B981),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ),
                        );
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
}
