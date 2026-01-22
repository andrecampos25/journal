import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
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
                    color: const Color(0xFF1E293B),
                  ),
                ),
                const Icon(LucideIcons.listTodo, size: 18, color: Color(0xFF94A3B8)),
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
                  separatorBuilder: (c, i) => Divider(height: 12, color: Colors.grey.withValues(alpha: 0.1)),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF64748B),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              task['title'] ?? 'Untitled',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF334155),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (task['due_date'] != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              (task['due_date'] as String).substring(11, 16),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: const Color(0xFF94A3B8),
                              ),
                            ),
                          ]
                        ],
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
