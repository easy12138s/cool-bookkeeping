import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../theme/app_colors.dart';

/// 权限请求工具类
/// 处理麦克风等运行时权限请求
class PermissionUtils {
  PermissionUtils._();

  /// 请求麦克风权限
  /// 返回权限状态
  static Future<PermissionStatus> requestMicrophonePermission() async {
    return await Permission.microphone.request();
  }

  /// 检查麦克风权限状态
  static Future<PermissionStatus> checkMicrophonePermission() async {
    return await Permission.microphone.status;
  }

  /// 显示权限请求弹窗
  /// 当用户拒绝权限时显示，引导用户去设置中开启
  static Future<bool> showPermissionDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  size: 32,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              const Text(
                '需要麦克风权限',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // 内容
              const Text(
                '语音记账功能需要使用麦克风来识别您的语音。请在设置中允许应用访问麦克风。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '取消',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '去设置',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (result == true) {
      // 打开应用设置页面
      await openAppSettings();
    }

    return result ?? false;
  }

  /// 显示权限被拒绝的提示
  static void showPermissionDeniedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '麦克风权限被拒绝，无法使用语音功能',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 完整的权限请求流程
  /// 返回是否获得了权限
  static Future<bool> handleMicrophonePermission(BuildContext context) async {
    // 检查当前权限状态
    var status = await checkMicrophonePermission();

    // 如果已经授权，直接返回 true
    if (status.isGranted) {
      return true;
    }

    // 如果权限被拒绝（不是永久拒绝），请求权限
    if (status.isDenied) {
      status = await requestMicrophonePermission();
      if (status.isGranted) {
        return true;
      }
    }

    // 如果是永久拒绝或限制状态，显示引导弹窗
    if (status.isPermanentlyDenied || status.isRestricted) {
      final openedSettings = await showPermissionDialog(context);
      if (openedSettings && context.mounted) {
        // 用户打开了设置，等待用户返回后重新检查权限状态
        // 使用延迟确保用户已经从设置页返回
        await Future.delayed(const Duration(milliseconds: 500));
        status = await checkMicrophonePermission();
        if (status.isGranted) {
          return true;
        }
      }
    }

    // 权限未获得
    if (context.mounted) {
      showPermissionDeniedSnackBar(context);
    }
    return false;
  }

  /// 应用启动时检查权限
  /// 仅在没有权限时显示弹窗，有权限时不做任何操作
  static Future<void> checkAndRequestPermission(BuildContext context) async {
    // 检查当前权限状态
    final status = await checkMicrophonePermission();

    // 如果已经有权限，直接返回，不做任何操作
    if (status.isGranted) {
      return;
    }

    // 如果没有权限，显示权限请求弹窗
    if (status.isDenied || status.isPermanentlyDenied || status.isRestricted) {
      await showInitialPermissionDialog(context);
    }
  }

  /// 应用启动时的权限请求弹窗
  /// 引导用户开启麦克风权限
  static Future<void> showInitialPermissionDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 图标
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  size: 32,
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: 16),
              // 标题
              const Text(
                '开启语音记账',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // 内容
              const Text(
                '酷记需要使用麦克风权限来识别您的语音，让记账更加便捷。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.divider),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '暂不开启',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        // 请求权限
                        final status = await requestMicrophonePermission();
                        if (!status.isGranted && context.mounted) {
                          // 如果用户拒绝，显示引导去设置的弹窗
                          final openedSettings = await showPermissionDialog(context);
                          if (openedSettings && context.mounted) {
                            // 等待用户从设置页返回后重新检查权限
                            await Future.delayed(const Duration(milliseconds: 500));
                            await checkMicrophonePermission();
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '立即开启',
                        style: TextStyle(fontSize: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
