import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/features/mirror/models/star.dart';
import 'package:life_os/features/mirror/widgets/nebula_canvas.dart';
import 'package:life_os/features/mirror/widgets/reflection_chat_overlay.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';

class MirrorScreen extends ConsumerStatefulWidget {
  const MirrorScreen({super.key});

  @override
  ConsumerState<MirrorScreen> createState() => _MirrorScreenState();
}

class _MirrorScreenState extends ConsumerState<MirrorScreen> {
  List<Star> _stars = [];
  List<StarThread> _threads = [];
  bool _isLoading = true;
  bool _isChatOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeStars());
  }

  Future<void> _initializeStars() async {
    final random = Random();
    final size = MediaQuery.of(context).size;

    final stars = <Star>[];

    // Fetch all tasks (not just today's) for richer correlations
    final allTasksAsync = await ref.read(allTasksProvider.future);
    for (final task in allTasksAsync.take(20)) { // Limit for performance
      stars.add(Star(
        id: task.id,
        position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        velocity: Offset((random.nextDouble() - 0.5) * 20, (random.nextDouble() - 0.5) * 10),
        radius: 8 + random.nextDouble() * 6,
        color: const Color(0xFF22D3EE), // Cyan for tasks
        type: StarType.task,
        linkedDataId: task.id,
        title: task.title,
        date: task.dueDate ?? task.createdAt,
        keywords: extractKeywords(task.title),
      ));
    }

    // Fetch all habits
    final allHabitsAsync = await ref.read(allHabitsProvider.future);
    for (final habit in allHabitsAsync.take(20)) {
      final title = habit['title'] as String? ?? '';
      final id = habit['id'] as String? ?? '';
      stars.add(Star(
        id: id,
        position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        velocity: Offset((random.nextDouble() - 0.5) * 15, (random.nextDouble() - 0.5) * 8),
        radius: 10 + random.nextDouble() * 8,
        color: const Color(0xFFFB923C), // Orange for habits
        type: StarType.habit,
        linkedDataId: id,
        title: title,
        date: DateTime.now(), // Habits are ongoing
        keywords: extractKeywords(title),
      ));
    }

    // Fetch journal entries
    final journalAsync = await ref.read(journalHistoryProvider.future);
    for (final entry in journalAsync.take(15)) {
      final text = entry.journalText ?? '';
      if (text.isEmpty) continue;
      stars.add(Star(
        id: entry.id ?? 'journal_${entry.entryDate.toIso8601String()}',
        position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        velocity: Offset((random.nextDouble() - 0.5) * 12, (random.nextDouble() - 0.5) * 6),
        radius: 12 + random.nextDouble() * 10,
        color: const Color(0xFFFBBF24), // Amber for journal
        type: StarType.journal,
        linkedDataId: entry.id,
        title: text.length > 50 ? '${text.substring(0, 50)}...' : text,
        date: entry.entryDate,
        keywords: extractKeywords(text),
      ));
    }

    // Compute correlations and create threads
    final threads = <StarThread>[];
    for (int i = 0; i < stars.length; i++) {
      for (int j = i + 1; j < stars.length; j++) {
        final strength = stars[i].correlationWith(stars[j]);
        if (strength > 0.2) { // Only keep meaningful correlations
          threads.add(StarThread(star1: stars[i], star2: stars[j], strength: strength));
        }
      }
    }

    // Add ambient stars for visual density
    for (int i = 0; i < 30; i++) {
      stars.add(Star(
        id: 'ambient_$i',
        position: Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
        velocity: Offset((random.nextDouble() - 0.5) * 8, (random.nextDouble() - 0.5) * 4),
        radius: 1 + random.nextDouble() * 3,
        color: Colors.white.withValues(alpha: 0.2 + random.nextDouble() * 0.3),
        type: StarType.task, // Ambient, not linked
        linkedDataId: null,
        title: '',
      ));
    }

    setState(() {
      _stars = stars;
      _threads = threads;
      _isLoading = false;
    });
  }

  void _onStarTapped(Star star) {
    if (star.linkedDataId == null || star.title.isEmpty) return;

    HapticFeedback.mediumImpact();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _InsightSheet(star: star),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.3, -0.5),
            radius: 1.5,
            colors: [
              Color(0xFF1E1B4B), // Deep indigo center
              Color(0xFF0F172A), // Dark slate edge
              Color(0xFF020617), // Near black
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Ambient glow layers
              Positioned(
                top: 100,
                left: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFF97316).withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 150,
                right: -30,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFFE2725B).withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // The Nebula
              if (!_isLoading)
                NebulaCanvas(
                  stars: _stars,
                  threads: _threads,
                  onStarTapped: _onStarTapped,
                ).animate().fadeIn(duration: 800.ms),
              
              // Loading indicator
              if (_isLoading)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Colors.white24, strokeWidth: 2),
                      const SizedBox(height: 16),
                      Text(
                        'Mapping your reality...',
                        style: GoogleFonts.lexend(
                          color: Colors.white38,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),

              // Back button
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: Colors.white54, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ),

              // Title
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    'THE MIRROR',
                    style: GoogleFonts.lexend(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ).animate().fadeIn(delay: 300.ms),
                ),
              ),

              // Legend
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendItem(color: const Color(0xFF22D3EE), label: 'Tasks'),
                    const SizedBox(width: 24),
                    _LegendItem(color: const Color(0xFFFB923C), label: 'Habits'),
                    const SizedBox(width: 24),
                    _LegendItem(color: const Color(0xFFFBBF24), label: 'Journal'),
                  ],
                ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),
              ),

              // Chat button
              Positioned(
                bottom: 80,
                right: 24,
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isChatOpen = true);
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFE2725B)],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(LucideIcons.messageCircle, color: Colors.white, size: 24),
                  ).animate().scale(delay: 600.ms, duration: 300.ms),
                ),
              ),

              // Chat overlay
              if (_isChatOpen)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _isChatOpen = false),
                    child: Container(color: Colors.black.withValues(alpha: 0.3)),
                  ),
                ),
              if (_isChatOpen)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: ReflectionChatOverlay(
                    onClose: () => setState(() => _isChatOpen = false),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _InsightSheet extends StatelessWidget {
  final Star star;

  const _InsightSheet({required this.star});

  String get _typeLabel {
    switch (star.type) {
      case StarType.task: return 'TASK';
      case StarType.habit: return 'HABIT';
      case StarType.journal: return 'JOURNAL';
    }
  }

  IconData get _typeIcon {
    switch (star.type) {
      case StarType.task: return LucideIcons.checkCircle;
      case StarType.habit: return LucideIcons.flame;
      case StarType.journal: return LucideIcons.bookOpen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E293B).withValues(alpha: 0.98),
            const Color(0xFF0F172A),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: star.color.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Type badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: star.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: star.color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_typeIcon, color: star.color, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            _typeLabel,
                            style: GoogleFonts.lexend(
                              color: star.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Title/Content
                Text(
                  star.title,
                  style: GoogleFonts.lexend(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
