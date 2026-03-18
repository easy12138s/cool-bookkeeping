import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/permission_utils.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'top_notification.dart';
import 'voice_recognition_sheet.dart';

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
    // 注册应用生命周期监听
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _recordingTimer?.cancel();
    // 移除应用生命周期监听
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 监听应用生命周期变化
    if (state == AppLifecycleState.paused) {
      // 应用进入后台（可能是去设置页了）
      _wasPaused = true;
    } else if (state == AppLifecycleState.resumed && _wasPaused) {
      // 应用从后台返回
      _wasPaused = false;
      // 重新检查权限状态，但不显示弹窗
      _refreshPermissionStatus();
    }
  }

  /// 刷新权限状态（静默检查，不显示弹窗）
  void _refreshPermissionStatus() async {
    final status = await Permission.microphone.status;
    if (kDebugMode) {
      print('App resumed, microphone permission status: $status');
    }
  }

  void _startRecording() async {
    if (_isStarting) return;
    _isStarting = true;

    // 请求麦克风权限
    final hasPermission = await PermissionUtils.handleMicrophonePermission(context);
    if (!hasPermission) {
      _isStarting = false;
      return;
    }

    // 清除之前的错误
    ref.read(voiceErrorMessageProvider.notifier).state = null;

    // 显示语音识别底部弹窗
    if (mounted) {
      showVoiceRecognitionSheet(context);
    }

    final controller = ref.read(voiceBookkeepingControllerProvider);
    await controller.startRecording();

    if (mounted) {
      _pulseController.repeat();
      _startRecordingTimer();
    }

    _isStarting = false;
  }

  /// 启动录音计时器
  /// 限制最大录音时长为15秒
  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingTimer?.cancel();
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      if (_recordingSeconds >= 15) {
        // 达到最大时长，自动停止录音
        timer.cancel();
        _stopRecording();
      }
    });
  }

  void _stopRecording() async {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    await controller.stopRecording();

    // 延迟关闭弹窗，让用户看到分析状态
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // 关闭语音识别弹窗
    hideVoiceRecognitionSheet(context);

    if (!mounted) return;

    // 解析语音输入（添加 await 和错误处理）
    try {
      await controller.parseVoiceInput();
    } catch (e) {
      if (kDebugMode) {
        print('Parse voice input error in button: $e');
      }
    }
  }

  void _cancelRecording() {
    _recordingTimer?.cancel();
    _pulseController.stop();
    _pulseController.reset();

    final controller = ref.read(voiceBookkeepingControllerProvider);
    controller.cancelRecording();

    // 关闭语音识别弹窗
    if (mounted) {
      hideVoiceRecognitionSheet(context);
    }
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
