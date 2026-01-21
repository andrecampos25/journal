import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/services/supabase_service.dart';
import 'dart:async';

class DailyEntryCard extends ConsumerStatefulWidget {
  const DailyEntryCard({super.key});

  @override
  ConsumerState<DailyEntryCard> createState() => _DailyEntryCardState();
}

class _DailyEntryCardState extends ConsumerState<DailyEntryCard> {
  double _moodValue = 5.0;
  final TextEditingController _journalController = TextEditingController();
  Timer? _debounce;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Verify data fetch on load
  }
  
  void _save(DateTime date) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 1), () {
       final service = ref.read(supabaseServiceProvider);
       service.upsertDailyEntry(date, mood: _moodValue.round(), journal: _journalController.text);
    });
  }

  String _getMoodEmoji(double value) {
    if (value <= 2) return '😢';
    if (value <= 4) return '😔';
    if (value <= 6) return '😐';
    if (value <= 8) return '🙂';
    return '🤩';
  }

  Color _getMoodColor(double value) {
     if (value <= 2) return const Color(0xFF64748B); // Slate
     if (value <= 4) return const Color(0xFF3B82F6); // Blue
     if (value <= 6) return const Color(0xFFF59E0B); // Amber
     if (value <= 8) return const Color(0xFF10B981); // Emerald
     return const Color(0xFF8B5CF6); // Violet
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(selectedDateProvider);
    final entryAsync = ref.watch(dailyEntryProvider(today));

    // Listen to data changes to update local state ONCE
    ref.listen(dailyEntryProvider(today), (previous, next) {
      if (next.hasValue && next.value != null) {
        final data = next.value!;
        if (mounted) {
           setState(() {
             if (data['mood_score'] != null) _moodValue = (data['mood_score'] as int).toDouble();
             if (data['journal_text'] != null && _journalController.text.isEmpty) {
                _journalController.text = data['journal_text'] as String;
             }
             _isLoading = false;
           });
        }
      }
    });

    final moodEmoji = _getMoodEmoji(_moodValue);
    final moodColor = _getMoodColor(_moodValue);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF94A3B8).withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'How are you?',
                style: GoogleFonts.lexend(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              AnimatedContainer(
                duration: 300.ms,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: moodColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  moodEmoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Mood Slider
          Theme(
            data: Theme.of(context).copyWith(
              sliderTheme: SliderThemeData(
                trackHeight: 12,
                activeTrackColor: moodColor,
                inactiveTrackColor: const Color(0xFFF1F5F9),
                thumbColor: Colors.white,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 4),
                overlayColor: moodColor.withValues(alpha: 0.2),
              ),
            ),
            child: Slider(
              value: _moodValue,
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) {
                if (value != _moodValue) HapticFeedback.selectionClick();
                setState(() => _moodValue = value);
                _save(today);
              },
            ),
          ),
          const SizedBox(height: 16),
          
          // Journal Input
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (text) => _save(today),
                controller: _journalController,
                maxLines: null,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: const Color(0xFF334155),
                  height: 1.5,
                ),
                decoration: InputDecoration(
                  hintText: 'What\'s on your mind today?',
                  hintStyle: GoogleFonts.inter(color: const Color(0xFF94A3B8)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
