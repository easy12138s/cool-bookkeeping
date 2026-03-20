import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// 语音识别状态枚举
enum SpeechState {
  /// 空闲状态
  idle,

  /// 正在监听（录音中）
  listening,

  /// 处理中
  processing,

  /// 错误状态
  error,
}

/// 语音识别初始化错误原因
enum SpeechInitErrorCause {
  /// 成功
  success,

  /// 权限被拒绝
  permissionDenied,

  /// 设备不支持语音识别
  deviceNotSupported,

  /// 语音识别服务不可用
  serviceNotAvailable,

  /// 其他错误
  unknown,
}

/// 语音服务
/// 封装 speech_to_text 包，提供语音识别功能
class SpeechService {
  final SpeechToText _speechToText = SpeechToText();

  final StreamController<SpeechState> _stateController =
      StreamController<SpeechState>.broadcast();
  final StreamController<String> _textController =
      StreamController<String>.broadcast();

  /// 语音识别状态流
  Stream<SpeechState> get stateStream => _stateController.stream;

  /// 识别文本流
  Stream<String> get textStream => _textController.stream;

  /// 最大录音时长（秒）
  static const int maxDuration = 15;

  /// 默认语言区域
  static const String localeId = 'zh_CN';

  bool _isInitialized = false;
  bool _isListening = false;

  /// 最后的错误原因
  SpeechInitErrorCause _lastErrorCause = SpeechInitErrorCause.success;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 获取最后的错误原因
  SpeechInitErrorCause get lastErrorCause => _lastErrorCause;

  /// 初始化语音识别
  /// 返回是否成功初始化
  Future<bool> initialize() async {
    if (_isInitialized) {
      _lastErrorCause = SpeechInitErrorCause.success;
      return true;
    }

    try {
      _lastErrorCause = SpeechInitErrorCause.unknown;

      if (kDebugMode) {
        print('[SpeechService] Initializing speech recognition...');
      }

      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          if (kDebugMode) {
            print('[SpeechService] initialize onError: $error');
          }

          final errorStr = error.toString().toLowerCase();
          if (errorStr.contains('permission') ||
              errorStr.contains('microphone') ||
              errorStr.contains('denied') ||
              errorStr.contains('not permitted')) {
            _lastErrorCause = SpeechInitErrorCause.permissionDenied;
          } else if (errorStr.contains('network') ||
              errorStr.contains('timeout') ||
              errorStr.contains('connection')) {
            // 网络问题
            _lastErrorCause = SpeechInitErrorCause.serviceNotAvailable;
          } else if (errorStr.contains('not available') ||
              errorStr.contains('unavailable') ||
              errorStr.contains('not listening')) {
            _lastErrorCause = SpeechInitErrorCause.serviceNotAvailable;
          } else if (errorStr.contains('device') ||
              errorStr.contains('support') ||
              errorStr.contains('not supported') ||
              errorStr.contains('no locale')) {
            _lastErrorCause = SpeechInitErrorCause.deviceNotSupported;
          } else {
            _lastErrorCause = SpeechInitErrorCause.unknown;
          }

          _isListening = false;
          _stateController.add(SpeechState.error);
        },
        onStatus: (status) {
          if (status == 'listening') {
            _isListening = true;
            _stateController.add(SpeechState.listening);
          } else if (status == 'done') {
            _isListening = false;
            _stateController.add(SpeechState.idle);
          } else if (status == 'notListening') {
            _isListening = false;
          }
        },
      );

      if (_isInitialized) {
        _lastErrorCause = SpeechInitErrorCause.success;
        if (kDebugMode) {
          print('[SpeechService] Initialization successful');
        }
      } else if (_lastErrorCause == SpeechInitErrorCause.unknown) {
        // 进一步诊断问题
        try {
          final available = await _speechToText.locales();
          if (kDebugMode) {
            print('[SpeechService] Available locales: $available');
          }
          if (available.isEmpty) {
            _lastErrorCause = SpeechInitErrorCause.deviceNotSupported;
            if (kDebugMode) {
              print('[SpeechService] No locales available - device not supported');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('[SpeechService] Error checking locales: $e');
          }
        }
      }

      if (kDebugMode) {
        print('[SpeechService] Initialization result: $_isInitialized, error cause: $_lastErrorCause');
      }

      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('[SpeechService] Initialization error: $e');
      }
      _lastErrorCause = SpeechInitErrorCause.unknown;
      _stateController.add(SpeechState.error);
      return false;
    }
  }

  /// 开始监听语音输入
  /// 超时时间为 15 秒
  Future<void> startListening() async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        _stateController.add(SpeechState.error);
        return;
      }
    }

    // 使用内部状态检查，避免 Web 平台上 isListening 不准确的问题
    if (_isListening) {
      if (kDebugMode) {
        print('Speech: Already listening, skipping start');
      }
      return;
    }

    try {
      _stateController.add(SpeechState.processing);

      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult || result.hasConfidenceRating) {
            _textController.add(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: maxDuration),
        localeId: localeId,
        cancelOnError: true,
        partialResults: true,
        listenMode: ListenMode.dictation,
      );

      // 延迟设置状态，等待 listen 真正开始
      await Future.delayed(const Duration(milliseconds: 100));
      _isListening = true;
    } catch (e) {
      if (kDebugMode) {
        print('Speech listen error: $e');
      }
      _isListening = false;
      _stateController.add(SpeechState.error);
    }
  }

  /// 停止监听语音输入
  /// 完成当前识别并返回结果
  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.stop();
      _isListening = false;
      _stateController.add(SpeechState.idle);
    } catch (e) {
      if (kDebugMode) {
        print('Speech stop error: $e');
      }
      _isListening = false;
      _stateController.add(SpeechState.error);
    }
  }

  /// 取消监听语音输入
  /// 丢弃当前识别结果
  Future<void> cancelListening() async {
    if (!_isListening) {
      return;
    }

    try {
      await _speechToText.cancel();
      _isListening = false;
      _stateController.add(SpeechState.idle);
    } catch (e) {
      if (kDebugMode) {
        print('Speech cancel error: $e');
      }
      _isListening = false;
      _stateController.add(SpeechState.error);
    }
  }

  /// 释放资源
  void dispose() {
    _stateController.close();
    _textController.close();
  }
}
