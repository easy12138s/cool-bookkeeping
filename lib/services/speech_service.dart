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

  /// 初始化语音识别
  /// 返回是否成功初始化
  Future<bool> initialize() async {
    if (_isInitialized) {
      return true;
    }

    try {
      _isInitialized = await _speechToText.initialize(
        onError: (error) {
          // Web 平台上 error 可能是 Event 类型，使用 dynamic 避免类型检查错误
          if (kDebugMode) {
            print('Speech error: $error');
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
      return _isInitialized;
    } catch (e) {
      if (kDebugMode) {
        print('Speech initialization error: $e');
      }
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
