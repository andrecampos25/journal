import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:life_os/features/dashboard/dashboard_providers.dart';
import 'package:life_os/core/models/models.dart';
import 'package:life_os/core/utils/time_utils.dart';
import 'package:life_os/core/utils/contextual_messages.dart';
import 'package:life_os/core/widgets/swipeable_card.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TodayTasksList extends ConsumerWidget {
  const TodayTasksList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(selectedDateProvider);
    final tasksAsync = ref.watch(todayTasksProvider(today));

    return Skeletonizer(
      enabled: tasksAsync.isLoading,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tasks',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Icon(LucideIcons.listTodo, size: 18, color: Theme.of(context).colorScheme.secondary),
              ],
            ),
            const SizedBox(height: 12),
            tasksAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (tasks) {
                if (tasks.isEmpty) {
                  return _buildEmptyState(context);
                }
                
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: tasks.length,
                  separatorBuilder: (c, i) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final notifier = ref.read(todayTasksProvider(today).notifier);
                    final isToggling = notifier.toggledTaskId == task.id;
                    
                    return _TaskItem(
                      task: task,
                      index: index,
                      today: today,
                      isToggling: isToggling,
                    )
                        .animate()
                        .fadeIn(
                          delay: Duration(milliseconds: 50 * index),
                          curve: Curves.easeOut,
                        )
                        .slideX(
                          begin: -0.1,
                          end: 0,
                          delay: Duration(milliseconds: 50 * index),
                          curve: Curves.easeOut,
                        );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.checkCircle2,
            size: 16,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 8),
          Text(
            'All caught up!',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(curve: Curves.easeOut)
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          curve: Curves.easeOut,
        );
  }
}

class _TaskItem extends ConsumerStatefulWidget {
  final Task task;
  final int index;
  final DateTime today;
  final bool isToggling;

  const _TaskItem({
    required this.task,
    required this.index,
    required this.today,
    required this.isToggling,
  });

  @override
  ConsumerState<_TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends ConsumerState<_TaskItem> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isCompleting = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    if (widget.isToggling || _isCompleting) return;

    setState(() => _isCompleting = true);
    
    // Play completion animation
    _animationController.forward();
    
    // Haptic feedback
    HapticFeedback.mediumImpact();
    
    // Wait for animation to finish
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Toggle task
    await ref.read(todayTasksProvider(widget.today).notifier).toggleTask(widget.task.id, true);
    
    setState(() => _isCompleting = false);
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isDone = task.isCompleted;
    
    // Time sensitivity
    TimeSensitivity? timeSensitivity;
    String? relativeTime;
    if (task.dueDate != null) {
      timeSensitivity = TimeUtils.getTimeSensitivity(task.dueDate!);
      relativeTime = TimeUtils.formatRelativeTime(task.dueDate!);
    }

    Color getTimeColor() {
      if (timeSensitivity == null) return Theme.of(context).colorScheme.secondary;
      switch (timeSensitivity) {
        case TimeSensitivity.overdue:
          return Colors.red;
        case TimeSensitivity.urgent:
          return Colors.orange;
        case TimeSensitivity.soon:
          return Colors.amber;
        case TimeSensitivity.normal:
          return Theme.of(context).colorScheme.secondary;
      }
    }

    Widget taskCard = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Opacity(
          opacity: _isCompleting ? 1.0 - _animationController.value : 1.0,
          child: Transform.translate(
            offset: Offset(0, _animationController.value * 10),
            child: GestureDetector(
              onTap: _handleToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.isToggling
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.05)
                      : isDone
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDone ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3) : Colors.transparent,
                  ),
                ),
                child: widget.isToggling
                    ? _buildLoadingState(context)
                    : Row(
                        children: [
                          _buildCheckbox(context, isDone),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: isDone ? FontWeight.w500 : FontWeight.w400,
                                color: isDone
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                                decoration: isDone ? TextDecoration.lineThrough : null,
                                decorationColor: Theme.of(context).colorScheme.primary,
                              ),
                              child: Text(
                                task.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          if (relativeTime != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: getTimeColor().withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                relativeTime,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: getTimeColor(),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
          ),
        );
      },
    );

    // Wrap with swipeable card
    return SwipeableCard(
      onSwipeRight: _handleToggle,
      rightLabel: 'Complete',
      rightIcon: Icons.check_circle,
      rightColor: Colors.green,
      child: taskCard,
    );
  }

  Widget _buildCheckbox(BuildContext context, bool isDone) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isDone ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: isDone ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor,
          width: 1.5,
        ),
        boxShadow: isDone
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: isDone
          ? const Icon(Icons.check, size: 16, color: Colors.white)
              .animate()
              .scale(delay: const Duration(milliseconds: 100))
          : null,
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 14,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: const Duration(milliseconds: 800)),
        ),
      ],
    );
  }
}
