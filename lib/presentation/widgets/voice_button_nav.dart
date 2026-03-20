import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/responsive.dart';
import '../../core/utils/permission_utils.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'top_notification.dart';
import 'voice_status_tooltip.dart';

/// 导航栏语音按钮
/// 嵌入底部导航栏的紧凑版本
class VoiceButtonNav extends ConsumerStatefulWidget {
  const VoiceButtonNav({super.key});

  @override
  ConsumerState<VoiceButtonNav> createState() => _VoiceButtonNavState();
}

class _VoiceButtonNavState extends ConsumerState<VoiceButtonNav>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pulseController;
  bool _isStarting = false;
  bool _isStopping = false; // 添加标志位，防止正常结束时触发取消
  Timer? _recordingTimer;
  int _recordingSeconds = 0;
  bool _wasPaused = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      _wasPaused = false;
      _refreshPermissionStatus();
    }
  }

  void _refreshPermissionStatus() async {
    final status = await Permission.microphone.status;
    if (kDebugMode) {
      print('App resumed, microphone permission status: $status');
    }
  }

  void _startRecording() async {
    if (_isStarting) return;
    _isStarting = true;

    if (kDebugMode) {
      print('[VoiceButtonNav] Starting recording...');
    }

    final hasPermission = await PermissionUtils.handleMicrophonePermission(context);
    if (kDebugMode) {
      print('[VoiceButtonNav] Permission result: $hasPermission');
    }

    if (!hasPermission) {
      if (kDebugMode) {
        print('[VoiceButtonNav] Permission denied, aborting');
      }
      _isStarting = false;
      return;
    }

    // 重置状态
    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.reset();

    if (kDebugMode) {
      print('[VoiceButtonNav] Calling startRecording');
    }
    await controller.startRecording();

    if (mounted) {
      _pulseController.repeat();
      _startRecordingTimer();
    }

    _isStarting = false;
  }

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      setState(() {}); // 更新 UI 显示时长
      if (_recordingSeconds >= 15) {
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    _isStopping = true; // 标记为正常结束
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    await controller.stopRecording();

    if (!mounted) return;

    // 解析语音输入
    try {
      await controller.parseVoiceInput();
    } catch (e) {
      if (kDebugMode) {
        print('Parse voice input error in button: $e');
      }
      // 错误时重置状态
      controller.reset();
    }
  }

  void _cancelRecording() {
    // 如果是正常结束触发的取消，忽略
    if (_isStopping) {
      _isStopping = false;
      return;
    }
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.cancelRecording();
    controller.reset();
  }

  @override
  Widget build(BuildContext context) {
    final speechState = ref.watch(speechStateProvider);
    final recognizedText = ref.watch(recognizedTextProvider);
    final isRecording = speechState == SpeechState.listening;
    final isProcessing = speechState == SpeechState.processing;

    // 监听错误信息并显示提示
    ref.listen<String?>(voiceErrorMessageProvider, (previous, next) {
      if (next != null && next.isNotEmpty) {
        TopNotification.error(context, next);
        // 错误显示后重置状态
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            ref.read(voiceBookkeepingControllerProvider).reset();
          }
        });
      }
    });

    // 响应式按钮尺寸（增大到 72px，便于长按操作）
    final buttonSize = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 72.0,
    );

    // 响应式图标尺寸（增大到 32px）
    final iconSize = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 32.0,
    );

    // 响应式加载指示器尺寸
    final indicatorSize = ResponsiveSpacing.getResponsiveSpacing(
      context,
      baseSpacing: 28.0,
    );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // 悬浮状态提示
        if (isRecording || isProcessing)
          VoiceStatusTooltip(
            state: speechState,
            recognizedText: recognizedText,
            recordingSeconds: _recordingSeconds,
            onCancel: isRecording ? _cancelRecording : null,
          ),

        // 语音按钮
        GestureDetector(
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
                  width: buttonSize,
                  height: buttonSize,
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
                        ? SizedBox(
                            width: indicatorSize,
                            height: indicatorSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            isRecording ? Icons.mic : Icons.mic_none,
                            size: iconSize,
                            color: Colors.white,
                          ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
