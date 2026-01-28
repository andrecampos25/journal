import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:ui' show ImageFilter;
import 'package:life_os/features/mirror/providers/reflection_chat_provider.dart';

class ReflectionChatOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const ReflectionChatOverlay({super.key, required this.onClose});

  @override
  ConsumerState<ReflectionChatOverlay> createState() => _ReflectionChatOverlayState();
}

class _ReflectionChatOverlayState extends ConsumerState<ReflectionChatOverlay> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    HapticFeedback.lightImpact();
    
    await ref.read(reflectionChatProvider.notifier).sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(reflectionChatProvider);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0F172A).withValues(alpha: 0.95),
            const Color(0xFF431407).withValues(alpha: 0.98), // Deep terracotta/brown
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            children: [
              // Header
              _buildHeader(),

              // Messages
              Expanded(
                child: chatAsync.when(
                  data: (state) => ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == state.messages.length && state.isLoading) {
                        return _buildTypingIndicator();
                      }
                      return _buildMessageBubble(state.messages[index], index);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.white))),
                ),
              ),

              // Input
              _buildInput(),
            ],
          ),
        ),
      ),
    ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF97316).withValues(alpha: 0.3),
                  const Color(0xFFE2725B).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white70, size: 18),
          ),
          const SizedBox(width: 12),
          Text(
            'THE MIRROR',
            style: GoogleFonts.lexend(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: widget.onClose,
            icon: const Icon(LucideIcons.x, color: Colors.white38, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ReflectionMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFE2725B)],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? const Color(0xFFF97316).withValues(alpha: 0.8)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16),
                border: message.isUser
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormattedText(message.text, message.isUser),
                  if (message.suggestion != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildSuggestionCard(message.suggestion!, index),
                    ),
                ],
              ),
            ),
          ),
          if (message.isUser) const SizedBox(width: 38),
        ],
      ),
    ).animate().fadeIn(delay: (50 * index).ms).slideX(
          begin: message.isUser ? 0.1 : -0.1,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }

  Widget _buildFormattedText(String text, bool isUser) {
    // Hide the triggers and suggestions from the UI
    final displayLines = text.split('\n')
        .where((line) => !line.trim().startsWith('INSIGHT:') && !line.trim().startsWith('SUGGESTION:'))
        .join('\n').trim();
    
    // Simple markdown-like formatting for **bold**
    final parts = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.+?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(displayLines)) {
      if (match.start > lastEnd) {
        parts.add(TextSpan(text: displayLines.substring(lastEnd, match.start)));
      }
      parts.add(TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < displayLines.length) {
      parts.add(TextSpan(text: displayLines.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: GoogleFonts.inter(
          color: isUser ? Colors.white : Colors.white70,
          fontSize: 14,
          height: 1.5,
        ),
        children: parts.isEmpty ? [TextSpan(text: displayLines)] : parts,
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion, int index) {
    final type = suggestion['type'] ?? 'task';
    final title = suggestion['title'] ?? '';
    final reason = suggestion['reason'] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                type == 'task' ? LucideIcons.checkCircle : LucideIcons.flame,
                color: const Color(0xFFF97316),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'PROACTIVE SUGGESTION',
                style: GoogleFonts.lexend(
                  color: const Color(0xFFF97316),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.lexend(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
          ),
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: GoogleFonts.inter(color: Colors.white60, fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref.read(reflectionChatProvider.notifier).dismissSuggestion(index);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Dismiss', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    ref.read(reflectionChatProvider.notifier).acceptSuggestion(suggestion);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFF97316),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                  ),
                  child: Text('Accept', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF97316), Color(0xFFE2725B)],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white38,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
        .fadeIn(delay: (index * 200).ms)
        .fadeOut(delay: (600 + index * 200).ms);
  }

  Widget _buildInput() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _textController,
                style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Reflect on your journey...',
                  hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.heavyImpact();
              _sendMessage();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF97316), Color(0xFFE2725B)],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(LucideIcons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
