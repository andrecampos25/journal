import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/core/models/models.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/features/tasks/widgets/task_creation_sheet.dart';
import 'package:intl/intl.dart';

class TaskManagementScreen extends ConsumerWidget {
  const TaskManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(allTasksProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Tasks',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTaskSheet(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(LucideIcons.plus, color: Theme.of(context).colorScheme.onPrimary),
        label: Text('New Task', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600)),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          if (tasks.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(LucideIcons.checkSquare, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                   const SizedBox(height: 16),
                   Text('No pending tasks.', style: GoogleFonts.inter(color: Colors.grey)),
                 ],
               ),
             );
          }

          final sortedTasks = List<Task>.from(tasks); // Ensure mutable

          return ReorderableListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: sortedTasks.length,
             onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) {
                  newIndex -= 1;
                }
                final item = sortedTasks.removeAt(oldIndex);
                sortedTasks.insert(newIndex, item);
                
                // Optimistic UI update (optional, but good for UX)
                // We mainly want to call the service to update DB
                final service = ref.read(supabaseServiceProvider);
                service.reorderTasks(sortedTasks);
                
                // Invalidate to fetch fresh order if needed, or rely on optimistics
                ref.invalidate(allTasksProvider);
             },
             proxyDecorator: (child, index, animation) {
               return AnimatedBuilder(
                 animation: animation,
                 builder: (BuildContext context, Widget? child) {
                   return Material(
                     elevation: 0,
                     color: Colors.transparent,
                     child: Transform.scale(
                        scale: 1.05,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 20,
                                spreadRadius: -5,
                              )
                            ]
                          ),
                          child: child,
                        ),
                     ),
                   );
                 },
                 child: child,
               );
             },
             itemBuilder: (context, index) {
               final task = sortedTasks[index];
               
               // Wrap with ReorderableDragStartListener for specific handle dragging if needed,
               // but ReorderableListView usually handles dragging on long press of the item by default.
               // However, user requested "grip dots". 
               // We will put the listeners INSIDE the tile on the handle.
               // Actually, ReorderableListView needs the index. 
               
               return ReorderableDragStartListener(
                 key: ValueKey(task.id),
                 index: index,
                 child: Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: _TaskTile(task: task, index: index),
                 ),
               );
             },
          );
        },
      ),
    );
  }
}

void showTaskSheet(BuildContext context, WidgetRef ref, [Task? task]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => TaskCreationSheet(task: task),
  );
}

class _TaskTile extends ConsumerWidget {
  final Task task;
  final int index; // Added rank index
  const _TaskTile({required this.task, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueDate = task.dueDate;
    final isOverdue = task.isOverdue;
    final rank = index + 1;
    final isTopPriority = rank <= 3;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isTopPriority 
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: isTopPriority ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
             // Rank Badge
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               decoration: BoxDecoration(
                 color: isTopPriority ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                 borderRadius: BorderRadius.circular(8),
               ),
               child: Text(
                 '#$rank',
                 style: GoogleFonts.lexend(
                   fontSize: 12,
                   fontWeight: FontWeight.w700,
                   color: isTopPriority ? Theme.of(context).colorScheme.primary : Colors.grey,
                 ),
               ),
             ),
             const SizedBox(width: 12),
             GestureDetector(
                onTap: () async {
                   HapticFeedback.lightImpact();
                   final service = ref.read(supabaseServiceProvider);
                   await service.toggleTaskCompletion(task.id, true);
                   ref.invalidate(allTasksProvider);
                   ref.invalidate(todayTasksProvider(DateTime.now()));
                },
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Icon(LucideIcons.circle, color: Theme.of(context).colorScheme.primary, size: 18),
                ),
             ),
          ],
        ),
        title: Text(
          task.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        subtitle: dueDate != null ? Row(
          children: [
            Icon(LucideIcons.calendar, size: 12, color: isOverdue ? Colors.redAccent : const Color(0xFF64748B)),
            const SizedBox(width: 4),
            Text(
              DateFormat('MMM d, h:mm a').format(dueDate),
              style: GoogleFonts.inter(
                color: isOverdue ? Colors.redAccent : const Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ) : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(LucideIcons.moreVertical, size: 18, color: Color(0xFF64748B)),
              onPressed: () => showTaskSheet(context, ref, task),
            ),
            // Grip Handle
            const Icon(Icons.drag_indicator, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }
}
