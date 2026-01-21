import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class JournalHistoryScreen extends ConsumerWidget {
  const JournalHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(journalHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Journal History',
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
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entries) {
          if (entries.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(LucideIcons.bookOpen, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                   const SizedBox(height: 16),
                   Text('No journal entries yet.', style: GoogleFonts.inter(color: Colors.grey)),
                 ],
               ),
             );
          }

          return ListView.separated(
             padding: const EdgeInsets.all(16),
             itemCount: entries.length,
             separatorBuilder: (c, i) => const SizedBox(height: 12),
             itemBuilder: (context, index) => _JournalEntryTile(entry: entries[index]),
          );
        },
      ),
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _JournalEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.parse(entry['entry_date']);
    final mood = entry['mood_score'] as int?;
    final journal = entry['journal_text'] as String?;

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, y').format(date),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              if (mood != null)
                Text(
                  _getMoodEmoji(mood.toDouble()),
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
          if (journal != null && journal.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              journal,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF475569),
                height: 1.5,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _getMoodEmoji(double value) {
    if (value <= 2) return '😢';
    if (value <= 4) return '😕';
    if (value <= 6) return '😐';
    if (value <= 8) return '🙂';
    return '😁';
  }
}
