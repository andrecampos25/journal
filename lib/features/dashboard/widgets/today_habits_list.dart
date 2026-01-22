import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/habits/habit_details_screen.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:confetti/confetti.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'dart:math';

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
                        color: const Color(0xFF1E293B),
                      ),
                    ),
                    const Icon(LucideIcons.checkCircle2, size: 18, color: Color(0xFF94A3B8)),
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
                              color: isDone ? const Color(0xFFECFDF5) : Colors.black.withValues(alpha: 0.02),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDone ? const Color(0xFF10B981).withValues(alpha: 0.3) : Colors.transparent,
                              ),
                            ),
                          child: Row(
                            children: [
                               GestureDetector(
                                onTap: () async {
                                   HapticFeedback.lightImpact();
                                   if (!isDone) _playConfetti(); 
                                   await ref.read(todayHabitsProvider(today).notifier).toggleHabit(habit.id, !isDone);
                                },
                                 child: AnimatedContainer(
                                  duration: 200.ms,
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isDone ? const Color(0xFF10B981) : Colors.white,
                                    borderRadius: BorderRadius.circular(7),
                                    border: Border.all(
                                      color: isDone ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isDone
                                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                                      : null,
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
                                            color: isDone ? const Color(0xFF047857) : const Color(0xFF334155),
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
