import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/features/mirror/services/life_ledger_service.dart';

class HabitCreationSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? habit;

  const HabitCreationSheet({super.key, this.habit});

  @override
  ConsumerState<HabitCreationSheet> createState() => _HabitCreationSheetState();
}

class _HabitCreationSheetState extends ConsumerState<HabitCreationSheet> {
  late TextEditingController _titleController;
  late String _selectedEmoji;
  late List<int> _selectedDays;
  final _emojis = ['✨', '📖', '🧘', '🏃', '💧', '🥗', '🍎', '💤', '✍️', '🎸', '💻', '🔋', '🧹', '🎨', '🎵'];
  final _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.habit?['title']);
    _selectedEmoji = widget.habit?['icon'] ?? '✨';
    _selectedDays = (widget.habit?['frequency'] as List?)?.map((e) => int.parse(e.toString())).toList() ?? [1, 2, 3, 4, 5, 6, 7];
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    HapticFeedback.mediumImpact();
    Navigator.pop(context); // Optimistic close

    final service = ref.read(supabaseServiceProvider);
    
    // Create/Update updates cache instantly (Optimistic)
    if (widget.habit == null) {
      await service.createHabit(title, icon: _selectedEmoji, frequency: _selectedDays);
      
      // Index for Life Ledger
      ref.read(lifeLedgerServiceProvider).indexContent(
        sourceType: 'habit',
        sourceId: 'manual_habit_${DateTime.now().millisecondsSinceEpoch}',
        content: title,
        sourceDate: DateTime.now(),
      );
    } else {
      await service.updateHabit(widget.habit!['id'], title, icon: _selectedEmoji, frequency: _selectedDays);
    }

    // Since getHabits() is now Cache-First, these invalidations will cause
    // an instant re-render with the new cached data.
    ref.invalidate(allHabitsProvider);
    ref.invalidate(todayHabitsProvider(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardSpace = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            spreadRadius: 10,
          )
        ]
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + keyboardSpace),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.habit == null ? 'New Habit' : 'Edit Habit',
                  style: GoogleFonts.lexend(fontSize: 20, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Title Input
                Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                   decoration: BoxDecoration(
                     color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
                     borderRadius: BorderRadius.circular(16),
                     border: Border.all(color: Colors.transparent),
                   ),
                   child: TextField(
                     controller: _titleController,
                     autofocus: widget.habit == null,
                     style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
                     decoration: InputDecoration(
                       hintText: 'What trigger do you want to build?',
                       hintStyle: GoogleFonts.inter(color: Colors.grey.withValues(alpha: 0.5)),
                       border: InputBorder.none,
                       icon: Text(_selectedEmoji, style: const TextStyle(fontSize: 24)),
                     ),
                   ),
                ),

                const SizedBox(height: 24),
                
                // Emoji Picker
                Text('Visual Anchor', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojis.length,
                    separatorBuilder: (c, i) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final e = _emojis[index];
                      final isSelected = _selectedEmoji == e;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedEmoji = e);
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.withValues(alpha: 0.1)
                            ),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 24),

                // Frequency Picker
                Text('Frequency', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(7, (index) {
                    final day = index + 1;
                    final isSelected = _selectedDays.contains(day);
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() {
                          if (isSelected && _selectedDays.length > 1) {
                            _selectedDays.remove(day);
                          } else if (!isSelected) {
                            _selectedDays.add(day);
                            _selectedDays.sort();
                          }
                        });
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: 40,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)
                          ),
                          boxShadow: isSelected ? [
                             BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                          ] : [],
                        ),
                        child: Text(
                          _weekDays[index],
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 32),

                // Save Button
                FilledButton(
                  onPressed: _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: Text(
                    'Save Habit',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
  }
}
