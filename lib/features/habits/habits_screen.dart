import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HabitsManagementScreen extends ConsumerWidget {
  const HabitsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(allHabitsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Manage Habits',
          style: GoogleFonts.lexend(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showHabitDialog(context, ref),
        backgroundColor: const Color(0xFF1E293B),
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: Text('New Habit', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          if (habits.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(LucideIcons.list, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                   const SizedBox(height: 16),
                   Text('No habits yet.', style: GoogleFonts.inter(color: Colors.grey)),
                 ],
               ),
             );
          }

          // Sort by archived (active first) then created_at
          final activeHabits = habits.where((h) => !(h['archived'] as bool)).toList();
          final archivedHabits = habits.where((h) => (h['archived'] as bool)).toList();

          return ListView(
             padding: const EdgeInsets.all(16),
             children: [
               if (activeHabits.isNotEmpty) ...[
                 _buildSectionHeader('Active'),
                 ...activeHabits.map((h) => _HabitTile(habit: h)).toList(),
               ],
               if (archivedHabits.isNotEmpty) ...[
                 const SizedBox(height: 24),
                 _buildSectionHeader('Archived'),
                 ...archivedHabits.map((h) => _HabitTile(habit: h)).toList(),
               ]
             ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.0,
          color: const Color(0xFF94A3B8),
        ),
      ),
    );
  }

  void _showHabitDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? habit]) {
    final titleController = TextEditingController(text: habit?['title']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(habit == null ? 'New Habit' : 'Edit Habit', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Read 10 pages',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                 final service = ref.read(supabaseServiceProvider);
                 if (habit == null) {
                   await service.createHabit(title);
                 } else {
                   await service.updateHabit(habit['id'], title);
                 }
                 ref.invalidate(allHabitsProvider);
                 // Also invalidate today's habits on dashboard
                 ref.invalidate(todayHabitsProvider(DateTime.now())); 
                 if (context.mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Map<String, dynamic> habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = habit['archived'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          habit['title'],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            color: isArchived ? Colors.grey : const Color(0xFF1E293B),
            decoration: isArchived ? TextDecoration.lineThrough : null,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                isArchived ? LucideIcons.archiveRestore : LucideIcons.archive,
                size: 18,
                color: isArchived ? Colors.blue : Colors.grey,
              ),
              onPressed: () async {
                 final service = ref.read(supabaseServiceProvider);
                 await service.setHabitArchived(habit['id'], !isArchived);
                 ref.invalidate(allHabitsProvider);
                 ref.invalidate(todayHabitsProvider(DateTime.now()));
              },
            ),
             if (!isArchived)
             IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18, color: Color(0xFF64748B)),
              onPressed: () => (context.findAncestorWidgetOfExactType<HabitsManagementScreen>() as dynamic)?._showHabitDialog(context, ref, habit) ?? _showEditFromTile(context, ref, habit),
            ),
          ],
        ),
      ),
    );
  }

  // Helper to access the dialog method since it's in the parent widget class but separate state? 
  // Actually, I can just copy the dialog logic or make it static/mixin. 
  // Or simpler: put the dialog function in a accessible place.
  // I'll reuse the logic by duplicating just slightly for safety or refactoring.
  // Refactoring: I'll put the dialog in a global function or mixin? 
  // No, I'll just instantiate the parent to call it? No that's wrong.
  // I will just implement the edit logic here directly.

  void _showEditFromTile(BuildContext context, WidgetRef ref, Map<String, dynamic> habit) {
      final titleController = TextEditingController(text: habit['title']);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Habit', style: GoogleFonts.lexend(fontWeight: FontWeight.w600)),
        content: TextField(
          controller: titleController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g., Read 10 pages',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
          ),
          FilledButton(
            onPressed: () async {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                 final service = ref.read(supabaseServiceProvider);
                 await service.updateHabit(habit['id'], title);
                 ref.invalidate(allHabitsProvider);
                 ref.invalidate(todayHabitsProvider(DateTime.now())); 
                 if (context.mounted) Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF1E293B)),
            child: Text('Save', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
