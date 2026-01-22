import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/core/utils/gamification_logic.dart';
import 'package:life_os/services/supabase_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class HabitDetailsScreen extends ConsumerWidget {
  final Map<String, dynamic> habit;
  const HabitDetailsScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitId = habit['id'];
    final logsAsync = ref.watch(habitLogsProvider(habitId));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(habit['icon'] ?? '✨', style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              habit['title'],
              style: GoogleFonts.lexend(fontWeight: FontWeight.w600, color: const Color(0xFF1E293B)),
            ),
          ],
        ),
      ),
      body: logsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (logs) {
          final currentStreak = GamificationLogic.calculateStreak(logs);
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(currentStreak, logs.length),
                const SizedBox(height: 24),
                _buildSectionHeader('Consistency Heatmap'),
                const SizedBox(height: 12),
                _buildHeatmap(logs),
                const SizedBox(height: 32),
                _buildSectionHeader('Recent History'),
                const SizedBox(height: 12),
                if (logs.isEmpty)
                   Center(child: Text('No history yet. Start today!', style: GoogleFonts.inter(color: Colors.grey)))
                else
                  ...logs.take(5).map((date) => _buildHistoryTile(date)).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.lexend(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF475569)),
    );
  }

  Widget _buildStatsGrid(int currentStreak, int totalCompletions) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Current Streak',
            value: '$currentStreak',
            subvalue: 'days',
            icon: LucideIcons.flame,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            label: 'Total Done',
            value: '$totalCompletions',
            subvalue: 'times',
            icon: LucideIcons.checkCircle,
            color: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmap(List<String> logs) {
    final now = DateTime.now();
    // Show last 35 days (5 weeks)
    final days = List.generate(35, (index) {
      final date = now.subtract(Duration(days: 34 - index));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      final isCompleted = logs.contains(dateStr);
      return {'date': date, 'done': isCompleted};
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: AspectRatio(
        aspectRatio: 2.5,
        child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, // 7 days of week
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
          ),
          itemCount: days.length,
          itemBuilder: (context, index) {
            final day = days[index];
            final isDone = day['done'] as bool;
            return Container(
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFF10B981) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHistoryTile(String dateStr) {
    final date = DateTime.parse(dateStr);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
         color: Colors.white,
         borderRadius: BorderRadius.circular(12),
         border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.calendarCheck, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 12),
          Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF1E293B)),
          ),
          const Spacer(),
          Text('Done', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF10B981))),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String subvalue;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.subvalue,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: GoogleFonts.lexend(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF1E293B))),
              const SizedBox(width: 4),
              Text(subvalue, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
        ],
      ),
    );
  }
}

final habitLogsProvider = FutureProvider.family<List<String>, String>((ref, habitId) async {
  final service = ref.watch(supabaseServiceProvider);
  return service.getHabitLogs(habitId);
});
