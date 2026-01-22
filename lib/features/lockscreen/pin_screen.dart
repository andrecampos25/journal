import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:life_os/services/offline_service.dart';
import 'package:pinput/pinput.dart';

class PinScreen extends ConsumerStatefulWidget {
  const PinScreen({super.key});

  @override
  ConsumerState<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends ConsumerState<PinScreen> {
  final TextEditingController _pinController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isError = false;

  @override
  void dispose() {
    _pinController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validatePin(String pin) {
    final correctPin = ref.read(offlineServiceProvider).vaultPin;
    if (pin == correctPin) {
      // Success
      context.go('/dashboard');
    } else {
      // Error
      setState(() {
        _isError = true;
        _pinController.clear();
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() => _isError = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fixed: withOpacity is deprecated in favor of withValues or keeping it if using older SDK.
    // Since we are on stable, withValues might not be there yet or withOpacity is fine.
    // I'll stick to withOpacity but suppress warning if needed, or check SDK version.
    // Actually, withOpacity is NOT deprecated in 3.24 (current stable). 
    // Wait, the analysis earlier said "info - 'withOpacity' is deprecated". 
    // That means I am on a VERY new Flutter (3.27 or beta?).
    // I will use withOpacity for now, simpler.

    const focusedBorderColor = Color(0xFF1E293B); // Slate 800
    const fillColor = Color(0xFFF1F5F9); // Slate 100
    const borderColor = Color(0xFFCBD5E1); // Slate 300

    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: GoogleFonts.lexend(
        fontSize: 22,
        color: const Color(0xFF1E293B),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        color: fillColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome Back',
              style: GoogleFonts.lexend(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ).animate().fadeIn().slideY(begin: -0.5, end: 0),
            const SizedBox(height: 8),
            Text(
              'Enter your PIN to access LifeOS',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 48),
            Pinput(
              length: 4,
              controller: _pinController,
              focusNode: _focusNode,
              useNativeKeyboard: false, // Disable native keyboard
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: focusedBorderColor, width: 2),
                ),
              ),
              errorPinTheme: defaultPinTheme.copyWith(
                decoration: defaultPinTheme.decoration!.copyWith(
                  border: Border.all(color: Colors.redAccent),
                  color: Colors.red.withValues(alpha: 0.05),
                ),
              ),
              onCompleted: _validatePin,
              pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
              showCursor: true,
              cursor: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    margin: const EdgeInsets.only(bottom: 9),
                    width: 22,
                    height: 1,
                    color: focusedBorderColor,
                  ),
                ],
              ),
            )
                .animate(target: _isError ? 1 : 0)
                .shake(duration: 400.ms, hz: 4)
                .tint(color: Colors.red.withValues(alpha: 0.1)),
            const Spacer(),
            _buildKeypad(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('1'),
              _buildKey('2'),
              _buildKey('3'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('4'),
              _buildKey('5'),
              _buildKey('6'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildKey('7'),
              _buildKey('8'),
              _buildKey('9'),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SizedBox(width: 70), // Spacer for 0 alignment
              _buildKey('0'),
              _buildKey('backspace', isIcon: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKey(String value, {bool isIcon = false}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isIcon) {
            if (_pinController.text.isNotEmpty) {
              _pinController.text = _pinController.text.substring(0, _pinController.text.length - 1);
            }
          } else {
            if (_pinController.text.length < 4) {
              _pinController.text += value;
              if (_pinController.text.length == 4) {
                _validatePin(_pinController.text);
              }
            }
          }
        },
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: isIcon
              ? const Icon(Icons.backspace_rounded, color: Color(0xFF1E293B), size: 24)
              : Text(
                  value,
                  style: GoogleFonts.lexend(
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
        ),
      ),
    ).animate().scale(duration: 150.ms, begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}
