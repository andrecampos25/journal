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

          return ListView.builder(
             padding: const EdgeInsets.all(16),
             itemCount: tasks.length,
             itemBuilder: (context, index) => _TaskTile(task: tasks[index]),
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
  const _TaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dueDate = task.dueDate;
    final isOverdue = task.isOverdue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: GestureDetector(
          onTap: () async {
             HapticFeedback.lightImpact();
             final service = ref.read(supabaseServiceProvider);
             await service.toggleTaskCompletion(task.id, true);
             ref.invalidate(allTasksProvider);
             ref.invalidate(todayTasksProvider(DateTime.now()));
          },
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            ),
            child: Icon(LucideIcons.circle, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
        ),
        title: Text(
          task.title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
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
        trailing: IconButton(
          icon: const Icon(LucideIcons.moreVertical, size: 18, color: Color(0xFF64748B)),
          onPressed: () {
            showTaskSheet(context, ref, task);
          },
        ),
      ),
    );
  }
}
