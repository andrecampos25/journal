import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_os/services/ai_service.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:life_os/features/mirror/services/life_ledger_service.dart';
import 'package:flutter/services.dart';

class NLPQuickBar extends ConsumerStatefulWidget {
  const NLPQuickBar({super.key});

  @override
  ConsumerState<NLPQuickBar> createState() => _NLPQuickBarState();
}

class _NLPQuickBarState extends ConsumerState<NLPQuickBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return AnimatedContainer(
      duration: 300.ms,
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark 
            ? (_isFocused ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05))
            : (_isFocused ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isFocused 
              ? primaryColor.withValues(alpha: 0.4) 
              : Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
          width: 1.5,
        ),
        boxShadow: _isFocused ? [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(
                  LucideIcons.sparkles,
                  size: 18,
                  color: _isFocused ? primaryColor : (isDark ? Colors.white54 : Colors.black45),
                ).animate(target: _isFocused ? 1 : 0)
                 .shimmer(duration: 2.seconds, color: primaryColor.withValues(alpha: 0.3))
                 .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add task or log habit...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? Colors.white38 : Colors.black38,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onSubmitted: (value) => _processInput(value),
                  ),
                ),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ).animate().fadeIn()
                else if (_controller.text.isNotEmpty)
                  IconButton(
                    icon: Icon(LucideIcons.arrowUpCircle, color: primaryColor),
                    onPressed: () => _processInput(_controller.text),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ).animate().fadeIn().scale(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _processInput(String input) async {
    if (input.trim().isEmpty || _isLoading) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.parseIntent(input);

      if (result != null && result['confidence'] >= 0.7) {
        final type = result['type'];
        final title = result['title'];
        final action = result['action'];

        if (type == 'task') {
          final dueDate = result['due_date'] != null 
              ? DateTime.parse(result['due_date']) 
              : null;
          await ref.read(supabaseServiceProvider).createTask(title, dueDate);
          ref.read(todayTasksProvider(ref.read(selectedDateProvider)).notifier).refresh();
          
          // Index for Life Ledger
          ref.read(lifeLedgerServiceProvider).indexContent(
            sourceType: 'task',
            sourceId: 'nlp_${DateTime.now().millisecondsSinceEpoch}',
            content: title,
            sourceDate: dueDate ?? DateTime.now(),
          );
        } else if (type == 'habit') {
          // Find habit by title
          final habits = ref.read(todayHabitsProvider(ref.read(selectedDateProvider))).value ?? [];
          final existingHabit = habits.where((h) => h.title.toLowerCase().contains(title.toLowerCase())).firstOrNull;

          if (existingHabit != null) {
            await ref.read(todayHabitsProvider(ref.read(selectedDateProvider)).notifier).toggleHabit(existingHabit.id, true);
          } else if (action == 'create') {
            await ref.read(supabaseServiceProvider).createHabit(title);
            ref.read(todayHabitsProvider(ref.read(selectedDateProvider)).notifier).refresh();
            
            // Index for Life Ledger
            ref.read(lifeLedgerServiceProvider).indexContent(
              sourceType: 'habit',
              sourceId: 'nlp_habit_${DateTime.now().millisecondsSinceEpoch}',
              content: title,
              sourceDate: DateTime.now(),
            );
          }
        } else if (type == 'journal') {
          final date = ref.read(selectedDateProvider);
          // For journal entries via NLP, we append to existing or create new
          await ref.read(supabaseServiceProvider).upsertDailyEntry(date, journal: title);
          ref.invalidate(dailyEntryProvider(date));
          
          // Index for Life Ledger
          ref.read(lifeLedgerServiceProvider).indexContent(
            sourceType: 'journal',
            sourceId: 'nlp_journal_${DateTime.now().millisecondsSinceEpoch}',
            content: title,
            sourceDate: date,
          );
        }

        _controller.clear();
        _focusNode.unfocus();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added: $title'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.9),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("I couldn't quite parse that. Try being more specific!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
