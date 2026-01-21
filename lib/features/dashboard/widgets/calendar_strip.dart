import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';

class CalendarStrip extends ConsumerWidget {
  const CalendarStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final now = DateTime.now();
    // Show 2 weeks: past 7 days + today + next 6 days? 
    // Usually journaling is about past and today. Maybe just past 14 days + future.
    // Let's do a window around selected date or just a fixed window from today.
    // Simple approach: List of dates ending today (or slightly in future).
    
    // We'll generate a list of 14 days ending today
    final days = List.generate(14, (index) => now.subtract(Duration(days: 13 - index)));
    // Add tomorrow just in case
    days.add(now.add(const Duration(days: 1)));
    
    return SizedBox(
      height: 85,
      child: ListView.separated(
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
              width: 56,
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF1E293B) 
                    : (isToday ? Colors.white.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.5)),
                borderRadius: BorderRadius.circular(16),
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
                       fontSize: 11,
                       fontWeight: FontWeight.w600,
                       color: isSelected ? Colors.white.withValues(alpha: 0.6) : const Color(0xFF64748B),
                     ),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     date.day.toString(),
                     style: GoogleFonts.lexend(
                       fontSize: 18,
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
