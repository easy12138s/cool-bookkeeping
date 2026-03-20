import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/parsed_result.dart';
import '../../data/models/record_model.dart';
import '../../services/baidu_speech_service.dart';
import '../../services/services.dart' as services;
import 'providers.dart';
import 'categories_provider.dart';
import 'records_provider.dart';

/// 语音识别状态
enum SpeechState {
  idle,           // 空闲状态
  initializing,   // 初始化中
  listening,      // 录音中
  processing,     // 处理中（松手后）
  success,        // 成功（解析完成）
  error,          // 错误状态
  cancelled,      // 用户取消
}

/// 语音识别错误类型
enum SpeechRecognitionErrorType {
  none,                   // 无错误
  initializationFailed,   // 初始化失败
  permissionDenied,       // 权限拒绝
  noSpeechDetected,       // 未检测到语音
  networkError,           // 网络错误
  parsingFailed,          // 解析失败
  unknown,                // 未知错误
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
  final BaiduSpeechService? _baiduSpeechService;

  VoiceBookkeepingController({
    required Ref ref,
    required services.SpeechService speechService,
    required services.LlmService llmService,
    BaiduSpeechService? baiduSpeechService,
  })  : _ref = ref,
        _speechService = speechService,
        _llmService = llmService,
        _baiduSpeechService = baiduSpeechService;

  bool _isRecording = false;
  bool _isProcessingAction = false; // 防抖标志
  SpeechRecognitionErrorType _lastErrorType = SpeechRecognitionErrorType.none;
  int _retryCount = 0;
  static const int _maxRetryCount = 2;
  
  StreamSubscription? _stateSubscription;
  StreamSubscription? _textSubscription;

  /// 获取当前状态
  SpeechState get currentState => _ref.read(speechStateProvider);

  /// 获取最后的错误类型
  SpeechRecognitionErrorType get lastErrorType => _lastErrorType;

  /// 状态转换方法 - 确保状态转换的正确性和清理
  void _transitionTo(SpeechState newState, {SpeechRecognitionErrorType? errorType}) {
    final oldState = _ref.read(speechStateProvider);
    
    if (kDebugMode) {
      print('[VoiceBookkeeping] State transition: $oldState -> $newState');
    }

    // 清理前一个状态
    _cleanupCurrentState(oldState);

    // 设置新状态
    _ref.read(speechStateProvider.notifier).state = newState;

    // 初始化新状态
    _initializeNewState(newState, errorType: errorType);
  }

  /// 清理当前状态
  void _cleanupCurrentState(SpeechState state) {
    switch (state) {
      case SpeechState.listening:
        _cleanupListeningState();
        break;
      case SpeechState.processing:
        _cleanupProcessingState();
        break;
      case SpeechState.error:
        _cleanupErrorState();
        break;
      default:
        break;
    }
  }

  /// 初始化新状态
  void _initializeNewState(SpeechState state, {SpeechRecognitionErrorType? errorType}) {
    switch (state) {
      case SpeechState.idle:
        _initializeIdleState();
        break;
      case SpeechState.error:
        _initializeErrorState(errorType ?? SpeechRecognitionErrorType.unknown);
        break;
      case SpeechState.success:
        _initializeSuccessState();
        break;
      default:
        break;
    }
  }

  /// 清理录音状态
  void _cleanupListeningState() {
    _isRecording = false;
    _ref.read(recordingStartTimeProvider.notifier).state = null;
  }

  /// 清理处理状态
  void _cleanupProcessingState() {
    // 处理状态通常不需要特殊清理
  }

  /// 清理错误状态
  void _cleanupErrorState() {
    _lastErrorType = SpeechRecognitionErrorType.none;
  }

  /// 初始化空闲状态
  void _initializeIdleState() {
    _isRecording = false;
    _isProcessingAction = false;
    _retryCount = 0;
    _ref.read(recognizedTextProvider.notifier).state = '';
    _ref.read(parsedResultsProvider.notifier).state = [];
    _ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
    _ref.read(batchSaveFailedRecordsProvider.notifier).state = [];
    _ref.read(voiceErrorMessageProvider.notifier).state = null;
    _ref.read(recordingStartTimeProvider.notifier).state = null;
  }

  /// 初始化错误状态
  void _initializeErrorState(SpeechRecognitionErrorType errorType) {
    _lastErrorType = errorType;
    _isRecording = false;
    _isProcessingAction = false;
    _ref.read(recordingStartTimeProvider.notifier).state = null;
  }

  /// 初始化成功状态
  void _initializeSuccessState() {
    _isRecording = false;
    _isProcessingAction = false;
    _retryCount = 0;
  }

  /// 检查是否可以执行操作（防抖）
  bool _canPerformAction() {
    if (_isProcessingAction) {
      if (kDebugMode) {
        print('[VoiceBookkeeping] Action blocked: already processing');
      }
      return false;
    }
    return true;
  }

  /// 开始处理操作
  void _startProcessingAction() {
    _isProcessingAction = true;
  }

  /// 结束处理操作
  void _endProcessingAction() {
    _isProcessingAction = false;
  }

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
  Future<bool> startRecording() async {
    // 防抖检查
    if (!_canPerformAction()) {
      if (kDebugMode) {
        print('[VoiceBookkeeping] startRecording blocked by debounce');
      }
      return false;
    }

    // 防止重复启动
    if (_isRecording) {
      if (kDebugMode) {
        print('[VoiceBookkeeping] Already recording, ignoring');
      }
      return false;
    }

    _startProcessingAction();

    try {
      // 转换到初始化状态
      _transitionTo(SpeechState.initializing);
      
      // 重置状态
      _ref.read(recognizedTextProvider.notifier).state = '';
      _ref.read(parsedResultsProvider.notifier).state = [];
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
      _ref.read(batchSaveFailedRecordsProvider.notifier).state = [];
      _ref.read(voiceErrorMessageProvider.notifier).state = null;

      // 检查是否使用百度语音
      final useBaidu = _baiduSpeechService != null && _baiduSpeechService.isConfigured;

      if (kDebugMode) {
        print('[VoiceBookkeeping] Using ${useBaidu ? 'Baidu' : 'Google'} speech service');
      }

      if (useBaidu) {
        // 使用百度语音识别
        final success = await _baiduSpeechService.startRecording();
        if (!success) {
          _setErrorState(
            '无法开始录音，请检查麦克风权限',
            SpeechRecognitionErrorType.permissionDenied,
          );
          return false;
        }

        _isRecording = true;
        _ref.read(recordingStartTimeProvider.notifier).state = DateTime.now();
        _transitionTo(SpeechState.listening);
        return true;
      }

      // 使用 Google 语音识别
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
        _handleInitializationError(errorCause);
        return false;
      }

      if (kDebugMode) {
        print('[VoiceBookkeeping] Initialization successful, starting to listen...');
      }

      _isRecording = true;
      _ref.read(recordingStartTimeProvider.notifier).state = DateTime.now();

      // 取消之前的订阅（防止内存泄漏）
      await _stateSubscription?.cancel();
      await _textSubscription?.cancel();

      // 订阅语音识别状态
      _stateSubscription = _speechService.stateStream.listen((state) {
        switch (state) {
          case services.SpeechState.listening:
            _transitionTo(SpeechState.listening);
            break;
          case services.SpeechState.idle:
            // 不在这里设置 idle，由 stopRecording 控制
            break;
          case services.SpeechState.error:
            _setErrorState(
              '语音识别出错，请重试',
              SpeechRecognitionErrorType.unknown,
            );
            break;
          case services.SpeechState.processing:
            _transitionTo(SpeechState.processing);
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
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Start recording error: $e');
      }
      _setErrorState(
        '启动录音失败: $e',
        SpeechRecognitionErrorType.unknown,
      );
      return false;
    } finally {
      _endProcessingAction();
    }
  }

  /// 处理初始化错误
  void _handleInitializationError(services.SpeechInitErrorCause? errorCause) {
    String errorMessage;
    SpeechRecognitionErrorType errorType;

    if (kDebugMode) {
      print('[VoiceBookkeeping] Initialization failed!');
      print('[VoiceBookkeeping] Error cause: $errorCause');
    }

    switch (errorCause) {
      case services.SpeechInitErrorCause.permissionDenied:
        errorMessage = '麦克风权限被拒绝，请前往系统设置中开启麦克风权限';
        errorType = SpeechRecognitionErrorType.permissionDenied;
        break;
      case services.SpeechInitErrorCause.deviceNotSupported:
        errorMessage = '您的设备不支持语音识别功能';
        errorType = SpeechRecognitionErrorType.initializationFailed;
        break;
      case services.SpeechInitErrorCause.serviceNotAvailable:
        errorMessage = '语音识别服务暂不可用，请检查网络连接后重试\n（语音识别需要连接 Google 服务）';
        errorType = SpeechRecognitionErrorType.networkError;
        break;
      case services.SpeechInitErrorCause.unknown:
      default:
        errorMessage = '语音识别初始化失败，请重试';
        errorType = SpeechRecognitionErrorType.initializationFailed;
    }

    _setErrorState(errorMessage, errorType);
  }

  /// 设置错误状态
  void _setErrorState(String message, SpeechRecognitionErrorType errorType) {
    _ref.read(voiceErrorMessageProvider.notifier).state = message;
    _transitionTo(SpeechState.error, errorType: errorType);
    _isRecording = false;
  }

  /// 停止录音
  /// 结束语音识别并触发解析
  Future<void> stopRecording() async {
    if (!_isRecording) {
      if (kDebugMode) {
        print('[VoiceBookkeeping] stopRecording: not recording, ignoring');
      }
      return;
    }

    try {
      // 转换到处理状态
      _transitionTo(SpeechState.processing);

      // 检查是否使用百度语音
      final useBaidu = _baiduSpeechService != null && _baiduSpeechService.isConfigured;

      if (useBaidu) {
        // 使用百度语音识别
        final result = await _baiduSpeechService.stopRecordingAndRecognize();
        _ref.read(recordingStartTimeProvider.notifier).state = null;
        
        if (result.success && result.text != null && result.text!.isNotEmpty) {
          _ref.read(recognizedTextProvider.notifier).state = result.text!;
          
          if (kDebugMode) {
            print('[VoiceBookkeeping] Baidu recognition result: ${result.text}');
          }
        } else {
          // 识别失败或无结果
          _handleBaiduRecognitionError(result);
        }
      } else {
        // 使用 Google 语音识别
        await _speechService.stopListening();
        _ref.read(recordingStartTimeProvider.notifier).state = null;
        // 保持 processing 状态，等待解析完成
      }
    } catch (e) {
      if (kDebugMode) {
        print('Stop recording error: $e');
      }
      _setErrorState(
        '停止录音失败: $e',
        SpeechRecognitionErrorType.unknown,
      );
    } finally {
      _isRecording = false;
    }
  }

  /// 处理百度识别错误
  void _handleBaiduRecognitionError(BaiduSpeechResult result) {
    String errorMsg;
    SpeechRecognitionErrorType errorType;

    switch (result.errorType) {
      case BaiduSpeechErrorType.notConfigured:
        errorMsg = '百度语音识别未配置，请在设置中配置';
        errorType = SpeechRecognitionErrorType.initializationFailed;
        break;
      case BaiduSpeechErrorType.networkError:
        errorMsg = '网络错误，请检查网络连接';
        errorType = SpeechRecognitionErrorType.networkError;
        break;
      case BaiduSpeechErrorType.authError:
        errorMsg = '百度语音认证失败，请检查 API Key';
        errorType = SpeechRecognitionErrorType.initializationFailed;
        break;
      case BaiduSpeechErrorType.permissionDenied:
        errorMsg = '麦克风权限被拒绝';
        errorType = SpeechRecognitionErrorType.permissionDenied;
        break;
      case BaiduSpeechErrorType.recordingError:
        errorMsg = result.errorMessage ?? '录音失败';
        errorType = SpeechRecognitionErrorType.unknown;
        break;
      case BaiduSpeechErrorType.recognitionError:
        errorMsg = result.errorMessage ?? '识别失败';
        errorType = SpeechRecognitionErrorType.unknown;
        break;
      default:
        // 检查是否是空结果
        if (result.text == null || result.text!.isEmpty) {
          errorMsg = '未检测到语音，请重试';
          errorType = SpeechRecognitionErrorType.noSpeechDetected;
        } else {
          errorMsg = result.errorMessage ?? '语音识别失败';
          errorType = SpeechRecognitionErrorType.unknown;
        }
    }

    _setErrorState(errorMsg, errorType);
  }

  /// 解析语音输入
  /// 调用 LLM 服务解析识别到的文本（支持多条）
  /// 解析完成后触发显示批量确认弹窗
  Future<void> parseVoiceInput() async {
    final text = _ref.read(recognizedTextProvider);
    if (text.isEmpty) {
      _setErrorState(
        '未识别到语音内容，请重试',
        SpeechRecognitionErrorType.noSpeechDetected,
      );
      return;
    }

    // 检查 LLM 配置
    if (!await _checkLlmConfiguration()) {
      _transitionTo(SpeechState.error, errorType: SpeechRecognitionErrorType.parsingFailed);
      return;
    }

    _transitionTo(SpeechState.processing);

    try {
      // 从数据库读取分类列表
      final categoriesAsync = _ref.read(categoriesProvider);
      final categories = categoriesAsync.valueOrNull ?? [];
      
      final expenseCategories = categories
          .where((c) => c.type == 0 && c.isEnabled)
          .map((c) => c.name)
          .toList();
      final incomeCategories = categories
          .where((c) => c.type == 1 && c.isEnabled)
          .map((c) => c.name)
          .toList();

      // 如果数据库为空，使用默认分类
      if (expenseCategories.isEmpty) {
        expenseCategories.addAll(['餐饮', '交通', '购物', '娱乐', '居住', '医疗', '教育', '其他']);
      }
      if (incomeCategories.isEmpty) {
        incomeCategories.addAll(['工资', '奖金', '投资', '兼职', '礼金', '其他']);
      }

      // 调用 LLM 解析（返回 List<ParsedResult>）
      final results = await _llmService.parseTransactions(
        text,
        expenseCategories: expenseCategories,
        incomeCategories: incomeCategories,
      );

      // 检查解析结果是否包含错误信息
      if (results.isNotEmpty && results.first.note != null && 
          results.first.note!.contains('未配置')) {
        _setErrorState(
          results.first.note!,
          SpeechRecognitionErrorType.parsingFailed,
        );
        return;
      }

      // 过滤掉没有金额的记录
      final validResults = results.where((r) => r.amount != null).toList();
      
      if (validResults.isEmpty) {
        _setErrorState(
          results.first.note ?? '无法解析金额，请手动输入',
          SpeechRecognitionErrorType.parsingFailed,
        );
        return;
      }

      _ref.read(parsedResultsProvider.notifier).state = validResults;

      // 触发显示批量确认弹窗
      _ref.read(showBatchConfirmationTriggerProvider.notifier).state = true;
      
      // 解析成功后保持 processing 状态，弹窗继续显示直到用户确认或取消
    } catch (e) {
      if (kDebugMode) {
        print('Parse voice input error: $e');
      }
      _setErrorState(
        '解析失败: $e\n请检查 API 配置或手动输入',
        SpeechRecognitionErrorType.parsingFailed,
      );
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
    if (!_isRecording) {
      // 即使不在录音，也要确保状态正确重置
      _transitionTo(SpeechState.cancelled);
      _transitionTo(SpeechState.idle);
      return;
    }

    try {
      // 检查是否使用百度语音
      final useBaidu = _baiduSpeechService != null && _baiduSpeechService.isConfigured;
      
      if (useBaidu) {
        await _baiduSpeechService.cancelRecording();
      } else {
        await _speechService.cancelListening();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Cancel recording error: $e');
      }
    } finally {
      _isRecording = false;
      
      // 取消订阅
      await _stateSubscription?.cancel();
      await _textSubscription?.cancel();
      _stateSubscription = null;
      _textSubscription = null;

      // 转换到取消状态，然后到空闲状态
      _transitionTo(SpeechState.cancelled);
      _transitionTo(SpeechState.idle);
    }
  }

  /// 释放资源
  /// 在控制器销毁时调用
  void dispose() {
    _stateSubscription?.cancel();
    _textSubscription?.cancel();
  }

  /// 重置所有状态
  /// 用于错误恢复或重新开始
  void reset() {
    if (kDebugMode) {
      print('[VoiceBookkeeping] Reset called, current state: ${_ref.read(speechStateProvider)}');
    }

    // 取消订阅
    _stateSubscription?.cancel();
    _textSubscription?.cancel();
    _stateSubscription = null;
    _textSubscription = null;
    
    // 重置内部状态
    _isRecording = false;
    _isProcessingAction = false;
    _retryCount = 0;
    _lastErrorType = SpeechRecognitionErrorType.none;
    
    // 使用状态转换方法重置
    _transitionTo(SpeechState.idle);
  }

  /// 从错误状态恢复
  /// 用于在错误后准备重新开始
  Future<void> recoverFromError() async {
    if (kDebugMode) {
      print('[VoiceBookkeeping] Recovering from error: $_lastErrorType');
    }

    // 根据错误类型决定是否可以自动重试
    switch (_lastErrorType) {
      case SpeechRecognitionErrorType.networkError:
        // 网络错误可以自动重试
        if (_retryCount < _maxRetryCount) {
          _retryCount++;
          await Future.delayed(const Duration(seconds: 1));
          reset();
          return;
        }
        break;
      case SpeechRecognitionErrorType.initializationFailed:
        // 初始化失败可以尝试重试
        if (_retryCount < _maxRetryCount) {
          _retryCount++;
          await Future.delayed(const Duration(milliseconds: 500));
          reset();
          return;
        }
        break;
      default:
        // 其他错误直接重置
        break;
    }

    reset();
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
  final baiduSpeechService = ref.watch(baiduSpeechServiceProvider);

  final controller = VoiceBookkeepingController(
    ref: ref,
    speechService: speechService,
    llmService: llmService,
    baiduSpeechService: baiduSpeechService,
  );
  
  // 确保控制器正确释放
  ref.onDispose(() {
    controller.dispose();
  });
  
  return controller;
});
