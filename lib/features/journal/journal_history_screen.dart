import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/models/models.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import 'package:life_os/features/journal/journal_editor_screen.dart';

class JournalHistoryScreen extends ConsumerStatefulWidget {
  const JournalHistoryScreen({super.key});

  @override
  ConsumerState<JournalHistoryScreen> createState() => _JournalHistoryScreenState();
}

class _JournalHistoryScreenState extends ConsumerState<JournalHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(journalHistoryProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Journal History',
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search memories...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (entries) {
          final filteredEntries = entries.where((e) {
            final text = e.journalText?.toLowerCase() ?? '';
            final date = DateFormat('MMMM d, y').format(e.entryDate).toLowerCase();
            return text.contains(_searchQuery) || date.contains(_searchQuery);
          }).toList();

          if (filteredEntries.isEmpty) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(32),
                 child: Column(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                     Icon(
                       _searchQuery.isEmpty ? LucideIcons.bookOpen : LucideIcons.searchX,
                       size: 48,
                       color: Colors.grey.withValues(alpha: 0.3),
                     ),
                     const SizedBox(height: 16),
                     Text(
                       _searchQuery.isEmpty ? 'No journal entries yet' : 'No matches found',
                       style: GoogleFonts.inter(
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                         color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                       ),
                     ),
                   ],
                 ),
               ),
             );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filteredEntries.length,
            separatorBuilder: (c, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final entry = filteredEntries[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => JournalEditorScreen(
                      date: entry.entryDate,
                      initialText: entry.journalText,
                      initialMood: entry.moodScore,
                    ),
                  ),
                ),
                child: _JournalEntryTile(entry: entry),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => JournalEditorScreen(date: DateTime.now()),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(LucideIcons.plus, color: Colors.white),
      ),
    );
  }
}

class _JournalEntryTile extends StatelessWidget {
  final DailyEntry entry;
  const _JournalEntryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM d, y').format(entry.entryDate),
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (entry.moodScore != null)
                Text(
                  entry.moodEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
            ],
          ),
          if (entry.journalText != null && entry.journalText!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.journalText!,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
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
}
