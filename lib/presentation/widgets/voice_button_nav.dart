import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'top_notification.dart';

/// 导航栏语音按钮
/// 嵌入底部导航栏的紧凑版本
class VoiceButtonNav extends ConsumerStatefulWidget {
  const VoiceButtonNav({super.key});

  @override
  ConsumerState<VoiceButtonNav> createState() => _VoiceButtonNavState();
}

class _VoiceButtonNavState extends ConsumerState<VoiceButtonNav>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startRecording() async {
    if (_isStarting) return;
    _isStarting = true;

    // 清除之前的错误
    ref.read(voiceErrorMessageProvider.notifier).state = null;

    final controller = ref.read(voiceBookkeepingControllerProvider);
    await controller.startRecording();

    if (mounted) {
      _pulseController.repeat();
    }

    _isStarting = false;
  }

  void _stopRecording() {
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.stopRecording();

    Future.delayed(const Duration(milliseconds: 500), () {
      controller.parseVoiceInput();
    });
  }

  void _cancelRecording() {
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.cancelRecording();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final isRecording = speechState == SpeechState.listening;
    final isProcessing = speechState == SpeechState.processing;

    // 监听错误信息并显示提示
    ref.listen<String?>(voiceErrorMessageProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        TopNotification.error(context, next);
      }
    });

    return GestureDetector(
      onLongPressStart: (_) => _startRecording(),
      onLongPressEnd: (_) => _stopRecording(),
      onLongPressCancel: () => _cancelRecording(),
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isRecording
              ? 1.0 + (_pulseController.value * 0.1)
              : 1.0;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isProcessing
                    ? AppColors.brandSecondary
                    : isRecording
                        ? AppColors.error
                        : AppColors.brandPrimary,
                boxShadow: isRecording
                    ? [
                        BoxShadow(
                          color: AppColors.error.withValues(
                            alpha: 0.3 + (_pulseController.value * 0.3),
                          ),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
              ),
              child: Center(
                child: isProcessing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Icon(
                        isRecording ? Icons.mic : Icons.mic_none,
                        size: 24,
                        color: Colors.white,
                      ),
              ),
            ),
          );
        },
      ),
    );
  }
}
