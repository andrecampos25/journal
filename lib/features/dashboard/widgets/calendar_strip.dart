import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';

class CalendarStrip extends ConsumerStatefulWidget {
  const CalendarStrip({super.key});

  @override
  ConsumerState<CalendarStrip> createState() => _CalendarStripState();
}

class _CalendarStripState extends ConsumerState<CalendarStrip> {
  late ScrollController _scrollController;
  // We'll generate a list of 14 days ending today (index 13) + 1 tomorrow (index 14)
  final int _todayIndex = 13; 

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    
    // Auto-scroll to Today after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        // Calculate offset: Index * (ItemWidth + SeparatorWidth)
        // ItemWidth = 50, Separator = 12 => 62
        // Center it roughly or just scroll to show it.
        // If we want it near the end, index 13 * 62 = 806.
        // Let's scroll to center it. 
        final offset = (_todayIndex * 62.0) - (MediaQuery.of(context).size.width / 2) + 25;
        _scrollController.jumpTo(offset.clamp(0.0, _scrollController.position.maxScrollExtent));
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();

    final days = List.generate(14, (index) => now.subtract(Duration(days: 13 - index)));
    days.add(now.add(const Duration(days: 1))); // Tomorrow
    
    return SizedBox(
      height: 70, // Reduced from 85
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final date = days[index];
          final isSelected = date.year == selectedDate.year && 
                             date.month == selectedDate.month && 
                             date.day == selectedDate.day;
                             
          final isToday = date.year == now.year && 
                          date.month == now.month && 
                          date.day == now.day;
          
          return GestureDetector(
            onTap: () {
               ref.read(selectedDateProvider.notifier).state = date;
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 50, // Reduced from 56
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1E293B) 
                    : (isToday ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected 
                      ? Colors.transparent 
                      : (isToday ? const Color(0xFF1E293B).withValues(alpha: 0.1) : Colors.transparent),
                ),
                boxShadow: isSelected 
                   ? [BoxShadow(color: const Color(0xFF1E293B).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]
                   : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Text(
                     DateFormat('E').format(date).toUpperCase(), // MON, TUE
                     style: GoogleFonts.inter(
                       fontSize: 10,
                       fontWeight: FontWeight.w600,
                       color: isSelected ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF64748B),
                     ),
                   ),
                   const SizedBox(height: 6),
                   Text(
                     date.day.toString(),
                     style: GoogleFonts.lexend(
                       fontSize: 16,
                       fontWeight: FontWeight.w700,
                       color: isSelected ? Colors.white : const Color(0xFF1E293B),
                     ),
                   ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
