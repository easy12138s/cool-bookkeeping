import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/parsed_result.dart';
import '../../services/services.dart' as services;
import 'providers.dart';

/// 语音识别状态
enum SpeechState {
  idle,
  listening,
  processing,
  error,
}

/// 语音状态 Provider
final speechStateProvider = StateProvider<SpeechState>((ref) {
  return SpeechState.idle;
});

/// 识别文本 Provider
final recognizedTextProvider = StateProvider<String>((ref) {
  return '';
});

/// 解析结果 Provider
final parsedResultProvider = StateProvider<ParsedResult?>((ref) {
  return null;
});

/// 录音开始时间 Provider（用于计算录音时长）
final recordingStartTimeProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// 错误信息 Provider
final voiceErrorMessageProvider = StateProvider<String?>((ref) {
  return null;
});

/// Voice Bookkeeping Controller
/// 管理语音记账的完整流程
class VoiceBookkeepingController {
  final Ref _ref;
  final services.SpeechService _speechService;
  final services.LlmService _llmService;

  VoiceBookkeepingController({
    required Ref ref,
    required services.SpeechService speechService,
    required services.LlmService llmService,
  })  : _ref = ref,
        _speechService = speechService,
        _llmService = llmService;

  bool _isRecording = false;

  /// 检查 LLM 是否已配置
  Future<bool> _checkLlmConfiguration() async {
    final isConfigured = await _llmService.isConfigured;
    if (!isConfigured) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '请先配置 API 密钥和基础 URL\n设置 → API 配置';
      return false;
    }
    return true;
  }

  /// 清除错误信息
  void clearError() {
    _ref.read(voiceErrorMessageProvider.notifier).state = null;
  }

  /// 开始录音
  /// 初始化语音识别并开始监听
  Future<void> startRecording() async {
    // 防止重复启动
    if (_isRecording) return;

    // 清除之前的错误
    clearError();

    try {
      _isRecording = true;
      _ref.read(speechStateProvider.notifier).state = SpeechState.processing;

      final initialized = await _speechService.initialize();
      if (!initialized) {
        _ref.read(voiceErrorMessageProvider.notifier).state =
            '语音识别初始化失败，请检查麦克风权限';
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
        _isRecording = false;
        return;
      }

      // 重置状态
      _ref.read(recognizedTextProvider.notifier).state = '';
      _ref.read(parsedResultProvider.notifier).state = null;
      _ref.read(recordingStartTimeProvider.notifier).state = DateTime.now();

      // 订阅语音识别状态
      _speechService.stateStream.listen((state) {
        switch (state) {
          case services.SpeechState.listening:
            _ref.read(speechStateProvider.notifier).state = SpeechState.listening;
            break;
          case services.SpeechState.idle:
            _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
            break;
          case services.SpeechState.error:
            _ref.read(voiceErrorMessageProvider.notifier).state =
                '语音识别出错，请重试';
            _ref.read(speechStateProvider.notifier).state = SpeechState.error;
            break;
          case services.SpeechState.processing:
            _ref.read(speechStateProvider.notifier).state = SpeechState.processing;
            break;
        }
      });

      // 订阅识别文本
      _speechService.textStream.listen((text) {
        if (text.isNotEmpty) {
          _ref.read(recognizedTextProvider.notifier).state = text;
        }
      });

      await _speechService.startListening();
    } catch (e) {
      if (kDebugMode) {
        print('Start recording error: $e');
      }
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '启动录音失败: $e';
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
      _isRecording = false;
    }
  }

  /// 停止录音
  /// 结束语音识别并触发解析
  Future<void> stopRecording() async {
    if (!_isRecording) return;

    try {
      await _speechService.stopListening();
      _ref.read(recordingStartTimeProvider.notifier).state = null;
      _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
    } catch (e) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '停止录音失败: $e';
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
    } finally {
      _isRecording = false;
    }
  }

  /// 解析语音输入
  /// 调用 LLM 服务解析识别到的文本
  Future<void> parseVoiceInput() async {
    final text = _ref.read(recognizedTextProvider);
    if (text.isEmpty) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '未识别到语音内容，请重试';
      return;
    }

    // 检查 LLM 配置
    if (!await _checkLlmConfiguration()) {
      return;
    }

    _ref.read(speechStateProvider.notifier).state = SpeechState.processing;
    clearError();

    try {
      // 获取分类列表
      final expenseCategories = ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      final incomeCategories = ['工资', '奖金', '投资', '兼职', '礼金', '其他'];

      final result = await _llmService.parseTransaction(
        text,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );

      // 检查解析结果是否包含错误信息
      if (result.note != null && result.note!.contains('未配置')) {
        _ref.read(voiceErrorMessageProvider.notifier).state = result.note;
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
        return;
      }

      _ref.read(parsedResultProvider.notifier).state = result;

      // 如果解析失败（没有金额），显示提示
      if (result.amount == null) {
        _ref.read(voiceErrorMessageProvider.notifier).state =
            result.note ?? '无法解析金额，请手动输入';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Parse voice input error: $e');
      }
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '解析失败: $e\n请检查 API 配置或手动输入';
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
    } finally {
      _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
    }
  }

  /// 保存记录
  /// 将解析结果保存到数据库
  /// 返回是否保存成功
  Future<bool> saveRecord() async {
    final result = _ref.read(parsedResultProvider);
    if (result == null || result.amount == null) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '没有可保存的记账数据';
      return false;
    }

    // TODO: 实现保存逻辑，需要找到对应的 categoryId
    // 这里需要调用 recordsProvider 的 addRecord 方法

    // 清空状态
    _ref.read(recognizedTextProvider.notifier).state = '';
    _ref.read(parsedResultProvider.notifier).state = null;
    clearError();

    return true;
  }

  /// 取消录音
  /// 放弃当前识别结果
  Future<void> cancelRecording() async {
    if (!_isRecording) return;

    try {
      await _speechService.cancelListening();
    } catch (e) {
      // 忽略取消时的错误
    } finally {
      _isRecording = false;
      _ref.read(recordingStartTimeProvider.notifier).state = null;
      _ref.read(recognizedTextProvider.notifier).state = '';
      _ref.read(parsedResultProvider.notifier).state = null;
      _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
      clearError();
    }
  }
}

/// Voice Bookkeeping Controller Provider
final voiceBookkeepingControllerProvider = Provider<VoiceBookkeepingController>(
  (ref) {
    final speechService = ref.watch(speechServiceProvider);
    final llmService = ref.watch(llmServiceProvider);
    return VoiceBookkeepingController(
      ref: ref,
      speechService: speechService,
      llmService: llmService,
    );
  },
);
