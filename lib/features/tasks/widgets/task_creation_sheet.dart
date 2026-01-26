import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:life_os/core/models/models.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';

class TaskCreationSheet extends ConsumerStatefulWidget {
  final Task? task;

  const TaskCreationSheet({super.key, this.task});

  @override
  ConsumerState<TaskCreationSheet> createState() => _TaskCreationSheetState();
}

class _TaskCreationSheetState extends ConsumerState<TaskCreationSheet> {
  late TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title);
    _selectedDate = widget.task?.dueDate;
    _selectedTime = _selectedDate != null ? TimeOfDay.fromDateTime(_selectedDate!) : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      DateTime? finalDate;
      if (_selectedDate != null) {
        final t = _selectedTime ?? const TimeOfDay(hour: 12, minute: 0);
        finalDate = DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, t.hour, t.minute);
      }

      final service = ref.read(supabaseServiceProvider);
      
      // Optimistic close
      if (mounted) Navigator.pop(context);

      if (widget.task == null) {
        await service.createTask(title, finalDate);
      } else {
        await service.updateTask(widget.task!.id, title, finalDate);
      }

      ref.invalidate(allTasksProvider);
      ref.invalidate(todayTasksProvider(DateTime.now()));
    } catch (e) {
      debugPrint('Error saving task: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
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
                  widget.task == null ? 'New Task' : 'Edit Task',
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
                     autofocus: widget.task == null,
                     style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
                     decoration: InputDecoration(
                       hintText: 'What needs doing?',
                       hintStyle: GoogleFonts.inter(color: Colors.grey.withValues(alpha: 0.5)),
                       border: InputBorder.none,
                       icon: const Icon(LucideIcons.checkSquare, color: Colors.grey),
                     ),
                   ),
                ),

                const SizedBox(height: 24),
                
                // Date & Time Pickers
                Text('Schedule', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now().subtract(const Duration(days: 365)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) setState(() => _selectedDate = date);
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedDate != null ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedDate != null ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)
                            ),
                            boxShadow: _selectedDate != null ? [
                               BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                            ] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.calendar, size: 18, color: _selectedDate != null ? Colors.white : Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null ? 'Set Date' : DateFormat('MMM d').format(_selectedDate!),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedDate != null ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          HapticFeedback.selectionClick();
                          final time = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime ?? TimeOfDay.now(),
                          );
                          if (time != null) setState(() => _selectedTime = time);
                        },
                        child: AnimatedContainer(
                          duration: 200.ms,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _selectedTime != null ? Theme.of(context).colorScheme.secondary : Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedTime != null ? Colors.transparent : Colors.grey.withValues(alpha: 0.2)
                            ),
                            boxShadow: _selectedTime != null ? [
                               BoxShadow(color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 4))
                            ] : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(LucideIcons.clock, size: 18, color: _selectedTime != null ? Colors.white : Theme.of(context).colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime == null ? 'Set Time' : _selectedTime!.format(context),
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: _selectedTime != null ? Colors.white : Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Save Button
                FilledButton(
                  onPressed: _isLoading ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Save Task',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
                
                if (widget.task != null) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context, 
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Task?'),
                          content: const Text('This cannot be undone.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
                          ],
                        )
                      );
                      
                      if (confirm == true) {
                        setState(() => _isLoading = true);
                        try {
                           await ref.read(supabaseServiceProvider).deleteTask(widget.task!.id);
                           ref.invalidate(allTasksProvider);
                           ref.invalidate(todayTasksProvider(DateTime.now()));
                           if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                           if (context.mounted) setState(() => _isLoading = false);
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('Delete Task', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    ).animate().slideY(begin: 0.1, end: 0, duration: 300.ms, curve: Curves.easeOutQuart);
  }
}
