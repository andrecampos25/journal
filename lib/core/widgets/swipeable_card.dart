import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable swipeable card widget with customizable swipe actions
class SwipeableCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeLeft;
  final String? rightLabel;
  final String? leftLabel;
  final Color rightColor;
  final Color leftColor;
  final IconData rightIcon;
  final IconData leftIcon;
  final bool enabled;

  const SwipeableCard({
    super.key,
    required this.child,
    this.onSwipeRight,
    this.onSwipeLeft,
    this.rightLabel,
    this.leftLabel,
    this.rightColor = Colors.green,
    this.leftColor = Colors.red,
    this.rightIcon = Icons.check,
    this.leftIcon = Icons.delete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled || (onSwipeRight == null && onSwipeLeft == null)) {
      return child;
    }

    return Dismissible(
      key: UniqueKey(),
      direction: _getDismissDirection(),
      confirmDismiss: (direction) async {
        // Trigger haptic feedback
        HapticFeedback.mediumImpact();

        // Execute the appropriate callback
        if (direction == DismissDirection.startToEnd && onSwipeRight != null) {
          onSwipeRight!();
        } else if (direction == DismissDirection.endToStart && onSwipeLeft != null) {
          onSwipeLeft!();
        }

        // Don't actually dismiss, just trigger the action
        return false;
      },
      background: _buildBackground(
        alignment: Alignment.centerLeft,
        color: rightColor,
        icon: rightIcon,
        label: rightLabel,
      ),
      secondaryBackground: _buildBackground(
        alignment: Alignment.centerRight,
        color: leftColor,
        icon: leftIcon,
        label: leftLabel,
      ),
      child: child,
    );
  }

  DismissDirection _getDismissDirection() {
    if (onSwipeRight != null && onSwipeLeft != null) {
      return DismissDirection.horizontal;
    } else if (onSwipeRight != null) {
      return DismissDirection.startToEnd;
    } else {
      return DismissDirection.endToStart;
    }
  }

  Widget _buildBackground({
    required Alignment alignment,
    required Color color,
    required IconData icon,
    String? label,
  }) {
    return Container(
      alignment: alignment,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          if (label != null) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
