import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/habits/habit_details_screen.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/features/habits/widgets/habit_creation_sheet.dart';
import 'package:life_os/core/utils/contextual_messages.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HabitsManagementScreen extends ConsumerWidget {
  const HabitsManagementScreen({super.key});

  static const _weekDaysFull = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(allHabitsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Manage Habits',
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
        onPressed: () => showHabitDialog(context, ref),
        backgroundColor: Theme.of(context).colorScheme.primary,
        icon: Icon(LucideIcons.plus, color: Theme.of(context).colorScheme.onPrimary),
        label: Text('New Habit', style: GoogleFonts.inter(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.w600)),
      ),
      body: habitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withValues(alpha: 0.05),
                      Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.list,
                      size: 64,
                      color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Build Better Habits! 💪',
                      style: GoogleFonts.lexend(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No habits yet',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      ContextualMessages.getMotivationalQuote(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
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
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
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
}

void showHabitDialog(BuildContext context, WidgetRef ref, [Map<String, dynamic>? habit]) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => HabitCreationSheet(habit: habit),
  );
}

void confirmDelete(BuildContext context, WidgetRef ref, String id) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Habit?'),
      content: const Text('This will permanently remove the habit and all its history. There is no undo.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
             final service = ref.read(supabaseServiceProvider);
             await service.deleteHabit(id);
             ref.invalidate(allHabitsProvider);
             ref.invalidate(todayHabitsProvider(DateTime.now()));
             if (context.mounted) {
               Navigator.pop(context); // Close confirm
               Navigator.pop(context); // Close edit dialog
             }
          },
          child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

class _HabitTile extends ConsumerWidget {
  final Map<String, dynamic> habit;
  const _HabitTile({required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isArchived = habit['archived'] as bool;

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => HabitDetailsScreen(habit: habit)));
      },
      child: Container(
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
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(habit['icon'] ?? '✨', style: const TextStyle(fontSize: 20)),
        ),
        title: Text(
          habit['title'],
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: isArchived ? Colors.grey : Theme.of(context).colorScheme.onSurface,
            decoration: isArchived ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _getFrequencyText(habit['frequency'] as List?),
          style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
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
                 HapticFeedback.lightImpact();
                 final service = ref.read(supabaseServiceProvider);
                 await service.setHabitArchived(habit['id'], !isArchived);
                 ref.invalidate(allHabitsProvider);
                 ref.invalidate(todayHabitsProvider(DateTime.now()));
              },
            ),
             if (!isArchived)
             IconButton(
              icon: const Icon(LucideIcons.pencil, size: 18, color: Color(0xFF64748B)),
              onPressed: () {
                HapticFeedback.lightImpact();
                showHabitDialog(context, ref, habit);
              },
            ),
          ],
        ),
      ),
    ),
   );
  }

  String _getFrequencyText(List? freq) {
    if (freq == null || freq.isEmpty || freq.length == 7) return 'Every day';
    final days = freq.map((d) => HabitsManagementScreen._weekDaysFull[int.parse(d.toString()) - 1]).toList();
    return days.join(', ');
  }
}
