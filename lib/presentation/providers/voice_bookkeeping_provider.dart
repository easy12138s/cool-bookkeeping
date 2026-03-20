import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/parsed_result.dart';
import '../../data/models/record_model.dart';
import '../../services/services.dart' as services;
import 'providers.dart';
import 'categories_provider.dart';
import 'records_provider.dart';

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

/// 解析结果列表 Provider（支持多条记账）
final parsedResultsProvider = StateProvider<List<ParsedResult>>((ref) {
  return [];
});

/// 录音开始时间 Provider（用于计算录音时长）
final recordingStartTimeProvider = StateProvider<DateTime?>((ref) {
  return null;
});

/// 错误信息 Provider
final voiceErrorMessageProvider = StateProvider<String?>((ref) {
  return null;
});

/// 显示批量确认弹窗触发 Provider
/// 当语音解析完成需要显示批量确认弹窗时设为 true
final showBatchConfirmationTriggerProvider = StateProvider<bool>((ref) {
  return false;
});

/// 批量保存失败记录 Provider
/// 存储批量保存时失败的记录列表
final batchSaveFailedRecordsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return [];
});

/// Voice Bookkeeping Controller
/// 管理语音记账的完整流程（支持多条记账）
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
  StreamSubscription? _stateSubscription;
  StreamSubscription? _textSubscription;

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

      // 尝试初始化语音识别，失败时重试一次
      bool initialized = await _speechService.initialize();
      
      // 如果第一次初始化失败，等待一段时间后重试
      if (!initialized) {
        if (kDebugMode) {
          print('[VoiceBookkeeping] First initialization failed, retrying after 500ms...');
        }
        await Future.delayed(const Duration(milliseconds: 500));
        initialized = await _speechService.initialize();
      }

      if (!initialized) {
        final errorCause = _speechService.lastErrorCause;
        String errorMessage;

        if (kDebugMode) {
          print('[VoiceBookkeeping] Initialization failed!');
          print('[VoiceBookkeeping] Error cause: $errorCause');
          print('[VoiceBookkeeping] _speechService.isInitialized: ${_speechService.isInitialized}');
        }

        switch (errorCause) {
          case services.SpeechInitErrorCause.permissionDenied:
            errorMessage = '麦克风权限被拒绝，请前往系统设置中开启麦克风权限';
            break;
          case services.SpeechInitErrorCause.deviceNotSupported:
            errorMessage = '您的设备不支持语音识别功能';
            break;
          case services.SpeechInitErrorCause.serviceNotAvailable:
            errorMessage = '语音识别服务暂不可用，请检查网络连接后重试\n（语音识别需要连接 Google 服务）';
            break;
          case services.SpeechInitErrorCause.unknown:
          default:
            errorMessage = '语音识别初始化失败，请重试';
        }

        if (kDebugMode) {
          print('[VoiceBookkeeping] Initialization failed: $errorMessage, cause: $errorCause');
        }

        _ref.read(voiceErrorMessageProvider.notifier).state = errorMessage;
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
        _isRecording = false;
        return;
      }

      if (kDebugMode) {
        print('[VoiceBookkeeping] Initialization successful, starting to listen...');
      }

      // 重置状态
      _ref.read(recognizedTextProvider.notifier).state = '';
      _ref.read(parsedResultsProvider.notifier).state = [];
      _ref.read(recordingStartTimeProvider.notifier).state = DateTime.now();
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
      _ref.read(batchSaveFailedRecordsProvider.notifier).state = [];

      // 取消之前的订阅（防止内存泄漏）
      await _stateSubscription?.cancel();
      await _textSubscription?.cancel();

      // 订阅语音识别状态
      _stateSubscription = _speechService.stateStream.listen((state) {
        switch (state) {
          case services.SpeechState.listening:
            _ref.read(speechStateProvider.notifier).state = SpeechState.listening;
            break;
          case services.SpeechState.idle:
            // 不在这里设置 idle，由 stopRecording 控制
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
      _textSubscription = _speechService.textStream.listen((text) {
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
      // 保持 processing 状态，等待解析完成
      _ref.read(speechStateProvider.notifier).state = SpeechState.processing;
    } catch (e) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '停止录音失败: $e';
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
    } finally {
      _isRecording = false;
    }
  }

  /// 解析语音输入
  /// 调用 LLM 服务解析识别到的文本（支持多条）
  /// 解析完成后触发显示批量确认弹窗
  Future<void> parseVoiceInput() async {
    final text = _ref.read(recognizedTextProvider);
    if (text.isEmpty) {
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '未识别到语音内容，请重试';
      _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
      return;
    }

    // 检查 LLM 配置
    if (!await _checkLlmConfiguration()) {
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
      return;
    }

    _ref.read(speechStateProvider.notifier).state = SpeechState.processing;
    clearError();

    try {
      // 获取分类列表
      final expenseCategories = ['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他'];
      final incomeCategories = ['工资', '奖金', '投资', '兼职', '礼金', '其他'];

      // 调用 LLM 解析（返回 List<ParsedResult>）
      final results = await _llmService.parseTransactions(
        text,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );

      // 检查解析结果是否包含错误信息
      if (results.isNotEmpty && results.first.note != null && 
          results.first.note!.contains('未配置')) {
        _ref.read(voiceErrorMessageProvider.notifier).state = results.first.note;
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
        return;
      }

      // 过滤掉没有金额的记录
      final validResults = results.where((r) => r.amount != null).toList();
      
      if (validResults.isEmpty) {
        _ref.read(voiceErrorMessageProvider.notifier).state =
            results.first.note ?? '无法解析金额，请手动输入';
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
        return;
      }

      _ref.read(parsedResultsProvider.notifier).state = validResults;

      // 触发显示批量确认弹窗
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = true;
    } catch (e) {
      if (kDebugMode) {
        print('Parse voice input error: $e');
      }
      _ref.read(voiceErrorMessageProvider.notifier).state =
          '解析失败: $e\n请检查 API 配置或手动输入';
      _ref.read(speechStateProvider.notifier).state = SpeechState.error;
    } finally {
      // 只有在出错时才设置为 error
      final hasError = _ref.read(voiceErrorMessageProvider) != null;
      if (hasError) {
        _ref.read(speechStateProvider.notifier).state = SpeechState.error;
      } else {
        _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
      }
    }
  }

  /// 批量保存记录
  /// 将解析结果列表保存到数据库
  /// 返回保存成功的记录数和失败的记录列表
  Future<BatchSaveResult> saveRecords(List<ParsedResult> results) async {
    if (results.isEmpty) {
      return BatchSaveResult(
        successCount: 0,
        failedRecords: [],
        errorMessage: '没有可保存的记账数据',
      );
    }

    final failedRecords = <Map<String, dynamic>>[];
    var successCount = 0;

    for (final result in results) {
      try {
        // 跳过无效的解析结果（没有金额）
        if (result.amount == null || result.amount! <= 0) {
          failedRecords.add({
            'result': result,
            'error': '金额无效',
          });
          continue;
        }

        // 查找对应的 categoryId
        final categoryId = await _findCategoryId(result.category, result.type);
        
        if (categoryId == null) {
          failedRecords.add({
            'result': result,
            'error': '未找到分类：${result.category}',
          });
          continue;
        }

        // 创建 RecordModel
        final record = RecordModel(
          id: const Uuid().v4(),
          amount: result.amount!,
          categoryId: categoryId,
          type: result.type == '收入' ? 1 : 0,
          note: result.note,
          createdAt: result.time ?? DateTime.now(),
        );

        // 保存到数据库
        await _ref.read(recordsProvider.notifier).addRecord(record);
        successCount++;
      } catch (e) {
        failedRecords.add({
          'result': result,
          'error': e.toString(),
        });
      }
    }

    // 清空状态
    if (failedRecords.isEmpty) {
      _ref.read(recognizedTextProvider.notifier).state = '';
      _ref.read(parsedResultsProvider.notifier).state = [];
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
      clearError();
    } else {
      _ref.read(batchSaveFailedRecordsProvider.notifier).state = failedRecords;
    }

    return BatchSaveResult(
      successCount: successCount,
      failedRecords: failedRecords,
      errorMessage: failedRecords.isNotEmpty 
          ? '${failedRecords.length}条记录保存失败' 
          : null,
    );
  }

  /// 根据分类名称和类型查找分类ID
  Future<String?> _findCategoryId(String categoryName, String type) async {
    return await _ref.read(categoriesProvider.notifier)
        .findCategoryIdByName(categoryName, type);
  }

  /// 更新解析结果列表
  /// 用于在批量确认弹窗中编辑后更新
  void updateParsedResults(List<ParsedResult> results) {
    _ref.read(parsedResultsProvider.notifier).state = results;
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
      _ref.read(parsedResultsProvider.notifier).state = [];
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
      _ref.read(batchSaveFailedRecordsProvider.notifier).state = [];
      _ref.read(speechStateProvider.notifier).state = SpeechState.idle;
      clearError();

      // 取消订阅
      await _stateSubscription?.cancel();
      await _textSubscription?.cancel();
      _stateSubscription = null;
      _textSubscription = null;
    }
  }

  /// 释放资源
  /// 在控制器销毁时调用
  void dispose() {
    _stateSubscription?.cancel();
    _textSubscription?.cancel();
  }
}

/// 批量保存结果
class BatchSaveResult {
  final int successCount;
  final List<Map<String, dynamic>> failedRecords;
  final String? errorMessage;

  BatchSaveResult({
    required this.successCount,
    required this.failedRecords,
    this.errorMessage,
  });

  bool get isSuccess => failedRecords.isEmpty;
}

/// Voice Bookkeeping Controller Provider
final voiceBookkeepingControllerProvider = Provider<VoiceBookkeepingController>((ref) {
  final speechService = ref.watch(speechServiceProvider);
  final llmService = ref.watch(llmServiceProvider);

  final controller = VoiceBookkeepingController(
    ref: ref,
    speechService: speechService,
    llmService: llmService,
  );
  
  // 确保控制器正确释放
  ref.onDispose(() {
    controller.dispose();
  });
  
  return controller;
});
