import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

/// 百度语音识别错误类型
enum BaiduSpeechErrorType {
  /// 配置缺失
  notConfigured,

  /// 网络错误
  networkError,

  /// 认证失败
  authError,

  /// 识别失败
  recognitionError,

  /// 录音权限被拒绝
  permissionDenied,

  /// 录音失败
  recordingError,

  /// 未知错误
  unknown,
}

/// 百度语音识别结果
class BaiduSpeechResult {
  final bool success;
  final String? text;
  final BaiduSpeechErrorType? errorType;
  final String? errorMessage;

  BaiduSpeechResult({
    required this.success,
    this.text,
    this.errorType,
    this.errorMessage,
  });

  factory BaiduSpeechResult.success(String text) {
    return BaiduSpeechResult(success: true, text: text);
  }

  factory BaiduSpeechResult.error(
    BaiduSpeechErrorType type, [
    String? message,
  ]) {
    return BaiduSpeechResult(
      success: false,
      errorType: type,
      errorMessage: message,
    );
  }
}

/// 百度语音识别服务
/// 
/// 使用百度语音识别 API 实现语音转文字功能
class BaiduSpeechService {
  /// 百度语音 API 基础 URL
  static const String _tokenUrl = 'https://aip.baidubce.com/oauth/2.0/token';
  static const String _asrUrl = 'https://vop.baidu.com/server_api';

  /// Access Token 缓存
  String? _accessToken;
  DateTime? _tokenExpireTime;

  /// 录音器
  final AudioRecorder _audioRecorder = AudioRecorder();

  /// 录音文件路径
  String? _recordingPath;

  /// 是否正在录音
  bool _isRecording = false;

  /// 配置信息
  String? _appId;
  String? _apiKey;
  String? _secretKey;

  /// 初始化服务
  /// 
  /// [appId] 百度语音 App ID
  /// [apiKey] 百度语音 API Key
  /// [secretKey] 百度语音 Secret Key
  void configure({
    String? appId,
    String? apiKey,
    String? secretKey,
  }) {
    _appId = appId;
    _apiKey = apiKey;
    _secretKey = secretKey;
    _accessToken = null;
    _tokenExpireTime = null;
  }

  /// 检查是否已配置
  bool get isConfigured =>
      _appId != null && _appId!.isNotEmpty &&
      _apiKey != null && _apiKey!.isNotEmpty &&
      _secretKey != null && _secretKey!.isNotEmpty;

  /// 是否正在录音
  bool get isRecording => _isRecording;

  /// 获取 Access Token
  Future<String?> _getAccessToken() async {
    // 检查缓存的 token 是否有效
    if (_accessToken != null && _tokenExpireTime != null) {
      if (DateTime.now().isBefore(_tokenExpireTime!)) {
        return _accessToken;
      }
    }

    if (_apiKey == null || _secretKey == null) {
      if (kDebugMode) {
        print('[BaiduSpeech] API Key or Secret Key is null');
      }
      return null;
    }

    try {
      final response = await http.post(
        Uri.parse('$_tokenUrl?grant_type=client_credentials'
            '&client_id=$_apiKey'
            '&client_secret=$_secretKey'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _accessToken = data['access_token'];
        final expiresIn = data['expires_in'] as int;
        // 提前 5 分钟过期，避免边界情况
        _tokenExpireTime = DateTime.now().add(Duration(seconds: expiresIn - 300));
        
        if (kDebugMode) {
          print('[BaiduSpeech] Got access token, expires in $expiresIn seconds');
        }
        
        return _accessToken;
      } else {
        if (kDebugMode) {
          print('[BaiduSpeech] Failed to get token: ${response.statusCode}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BaiduSpeech] Error getting token: $e');
      }
      return null;
    }
  }

  /// 开始录音
  Future<bool> startRecording() async {
    if (_isRecording) {
      if (kDebugMode) {
        print('[BaiduSpeech] Already recording');
      }
      return true;
    }

    // 检查麦克风权限
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (kDebugMode) {
        print('[BaiduSpeech] Microphone permission denied');
      }
      return false;
    }

    try {
      // 获取临时目录
      final directory = await getTemporaryDirectory();
      _recordingPath = '${directory.path}/speech_recording.m4a';

      // 开始录音（使用 AAC 格式，百度支持）
      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          sampleRate: 16000,
          numChannels: 1,
        ),
        path: _recordingPath!,
      );

      _isRecording = true;
      
      if (kDebugMode) {
        print('[BaiduSpeech] Started recording to $_recordingPath');
      }
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('[BaiduSpeech] Error starting recording: $e');
      }
      return false;
    }
  }

  /// 停止录音并识别
  Future<BaiduSpeechResult> stopRecordingAndRecognize() async {
    if (!_isRecording) {
      return BaiduSpeechResult.error(
        BaiduSpeechErrorType.recordingError,
        '未在录音',
      );
    }

    try {
      // 停止录音
      final path = await _audioRecorder.stop();
      _isRecording = false;

      if (path == null) {
        return BaiduSpeechResult.error(
          BaiduSpeechErrorType.recordingError,
          '录音文件路径为空',
        );
      }

      if (kDebugMode) {
        print('[BaiduSpeech] Stopped recording, file: $path');
      }

      // 读取音频文件
      final file = File(path);
      if (!await file.exists()) {
        return BaiduSpeechResult.error(
          BaiduSpeechErrorType.recordingError,
          '录音文件不存在',
        );
      }

      final audioBytes = await file.readAsBytes();
      
      if (kDebugMode) {
        print('[BaiduSpeech] Audio file size: ${audioBytes.length} bytes');
      }

      // 调用百度语音识别 API
      return await _recognize(audioBytes);
    } catch (e) {
      _isRecording = false;
      if (kDebugMode) {
        print('[BaiduSpeech] Error stopping recording: $e');
      }
      return BaiduSpeechResult.error(
        BaiduSpeechErrorType.recordingError,
        '停止录音失败: $e',
      );
    }
  }

  /// 调用百度语音识别 API
  Future<BaiduSpeechResult> _recognize(List<int> audioBytes) async {
    // 检查配置
    if (!isConfigured) {
      return BaiduSpeechResult.error(
        BaiduSpeechErrorType.notConfigured,
        '百度语音识别未配置',
      );
    }

    // 获取 Access Token
    final token = await _getAccessToken();
    if (token == null) {
      return BaiduSpeechResult.error(
        BaiduSpeechErrorType.authError,
        '获取 Access Token 失败',
      );
    }

    try {
      // 构建请求
      final response = await http.post(
        Uri.parse('$_asrUrl?cuid=$_appId&token=$token&dev_pid=1537'),
        headers: {
          'Content-Type': 'audio/aac; rate=16000',
        },
        body: audioBytes,
      );

      if (kDebugMode) {
        print('[BaiduSpeech] API response: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {
          print('[BaiduSpeech] Recognition result: $data');
        }

        final errNo = data['err_no'];
        final result = data['result'] as List?;

        if (errNo == 0 && result != null && result.isNotEmpty) {
          // 识别成功
          final text = result.join('');
          return BaiduSpeechResult.success(text);
        } else {
          // 识别失败
          final errMsg = data['err_msg'] ?? '识别失败';
          return BaiduSpeechResult.error(
            BaiduSpeechErrorType.recognitionError,
            '识别失败: $errMsg',
          );
        }
      } else {
        return BaiduSpeechResult.error(
          BaiduSpeechErrorType.networkError,
          '网络请求失败: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('[BaiduSpeech] Recognition error: $e');
      }
      return BaiduSpeechResult.error(
        BaiduSpeechErrorType.networkError,
        '网络错误: $e',
      );
    }
  }

  /// 取消录音
  Future<void> cancelRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      _isRecording = false;
      
      // 删除录音文件
      if (_recordingPath != null) {
        try {
          final file = File(_recordingPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      
      if (kDebugMode) {
        print('[BaiduSpeech] Recording cancelled');
      }
    }
  }

  /// 释放资源
  void dispose() {
    _audioRecorder.dispose();
  }
}
