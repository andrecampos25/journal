import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/models/models.dart';
import 'package:skeletonizer/skeletonizer.dart';

class TodayTasksList extends ConsumerWidget {
  const TodayTasksList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(todayTasksProvider(today));

    return Skeletonizer(
      enabled: tasksAsync.isLoading,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(LucideIcons.listTodo, size: 18, color: Theme.of(context).colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 12),
            tasksAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                   return Padding(
                     padding: const EdgeInsets.symmetric(vertical: 8.0),
                     child: Center(child: Text('No tasks due', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13))),
                   );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: tasks.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isDone = task.isCompleted;
                    
                    return GestureDetector(
                      onTap: () async {
                        HapticFeedback.lightImpact();
                        await ref.read(todayTasksProvider(today).notifier).toggleTask(task.id, true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDone 
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDone ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDone ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(7),
                                border: Border.all(
                                  color: isDone ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
                                  width: 1.5,
                                ),
                                boxShadow: isDone ? [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ] : null,
                              ),
                              child: isDone
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                task.title,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                                  color: isDone 
                                      ? Theme.of(context).colorScheme.primary 
                                      : Theme.of(context).colorScheme.onSurface,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                  decorationColor: Theme.of(context).colorScheme.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (task.formattedDueTime != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  task.formattedDueTime!,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                ),
                              ),
                            ]
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
    );
  }
}
