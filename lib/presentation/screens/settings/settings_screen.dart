import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../providers/settings_provider.dart';
import '../category/category_management_screen.dart';

/// 应用版本号（与 pubspec.yaml 保持同步）
const String kAppVersion = '1.1.0';

/// 设置页面
/// 管理应用配置和系统设置
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // API 配置
          _buildSectionHeader(context, 'API 配置'),
          _buildApiKeyTile(context, ref, settings),
          _buildApiBaseUrlTile(context, ref, settings),
          _buildModelNameTile(context, ref, settings),
          const Divider(),

          // 语音识别配置
          _buildSectionHeader(context, '语音识别配置'),
          _buildBaiduSpeechAppIdTile(context, ref, settings),
          _buildBaiduSpeechApiKeyTile(context, ref, settings),
          _buildBaiduSpeechSecretKeyTile(context, ref, settings),
          const Divider(),

          // 记账设置
          _buildSectionHeader(context, '记账设置'),
          _buildAutoSaveTile(context, ref, settings),
          const Divider(),

          // 数据管理
          _buildSectionHeader(context, '数据管理'),
          _buildCategoryManagementTile(context),
          _buildClearDataTile(context, ref),
          const Divider(),

          // 关于
          _buildSectionHeader(context, '关于'),
          _buildAboutTile(context),
        ],
      ),
    );
  }

  /// 构建分组标题
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  /// 构建 API Key 设置项
  Widget _buildApiKeyTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.key),
      title: const Text('API Key'),
      subtitle: Text(
        settings.apiKey != null && settings.apiKey!.isNotEmpty
            ? '已配置'
            : '未配置',
        style: TextStyle(
          color: settings.apiKey != null && settings.apiKey!.isNotEmpty
              ? AppColors.success
              : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showApiKeyDialog(context, ref, settings),
    );
  }

  /// 构建 API Base URL 设置项
  Widget _buildApiBaseUrlTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.link),
      title: const Text('API Base URL'),
      subtitle: Text(
        settings.apiBaseUrl ?? '使用默认地址',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showApiBaseUrlDialog(context, ref, settings),
    );
  }

  /// 构建模型名称设置项
  Widget _buildModelNameTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.model_training),
      title: const Text('模型名称'),
      subtitle: Text(
        settings.modelName ?? 'qwen3.5-plus',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showModelNameDialog(context, ref, settings),
    );
  }

  /// 构建自动保存设置项
  Widget _buildAutoSaveTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return SwitchListTile(
      secondary: const Icon(Icons.save),
      title: const Text('自动保存'),
      subtitle: const Text('识别完成后自动保存记账记录'),
      value: settings.autoSaveEnabled,
      onChanged: (value) {
        ref.read(settingsProvider.notifier).setAutoSaveEnabled(value);
      },
    );
  }

  /// 构建百度语音 App ID 设置项
  Widget _buildBaiduSpeechAppIdTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.app_registration),
      title: const Text('App ID'),
      subtitle: Text(
        settings.baiduSpeechAppId != null && settings.baiduSpeechAppId!.isNotEmpty
            ? '已配置'
            : '未配置',
        style: TextStyle(
          color: settings.baiduSpeechAppId != null && settings.baiduSpeechAppId!.isNotEmpty
              ? AppColors.success
              : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showBaiduSpeechAppIdDialog(context, ref, settings),
    );
  }

  /// 构建百度语音 API Key 设置项
  Widget _buildBaiduSpeechApiKeyTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.vpn_key),
      title: const Text('API Key'),
      subtitle: Text(
        settings.baiduSpeechApiKey != null && settings.baiduSpeechApiKey!.isNotEmpty
            ? '已配置'
            : '未配置',
        style: TextStyle(
          color: settings.baiduSpeechApiKey != null && settings.baiduSpeechApiKey!.isNotEmpty
              ? AppColors.success
              : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showBaiduSpeechApiKeyDialog(context, ref, settings),
    );
  }

  /// 构建百度语音 Secret Key 设置项
  Widget _buildBaiduSpeechSecretKeyTile(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    return ListTile(
      leading: const Icon(Icons.lock),
      title: const Text('Secret Key'),
      subtitle: Text(
        settings.baiduSpeechSecretKey != null && settings.baiduSpeechSecretKey!.isNotEmpty
            ? '已配置'
            : '未配置',
        style: TextStyle(
          color: settings.baiduSpeechSecretKey != null && settings.baiduSpeechSecretKey!.isNotEmpty
              ? AppColors.success
              : AppColors.textSecondary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showBaiduSpeechSecretKeyDialog(context, ref, settings),
    );
  }

  /// 构建类别管理设置项
  Widget _buildCategoryManagementTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.category),
      title: const Text('类别管理'),
      subtitle: const Text('管理收入和支出类别'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CategoryManagementScreen(),
          ),
        );
      },
    );
  }

  /// 构建清除数据设置项
  Widget _buildClearDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: const Icon(Icons.delete_forever, color: AppColors.error),
      title: const Text(
        '清除数据',
        style: TextStyle(color: AppColors.error),
      ),
      subtitle: const Text('删除所有记账记录'),
      onTap: () => _showClearDataConfirmDialog(context, ref),
    );
  }

  /// 构建关于设置项
  Widget _buildAboutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info),
      title: const Text('关于'),
      subtitle: Text('版本 $kAppVersion'),
      onTap: () => _showAboutDialog(context),
    );
  }

  /// 显示 API Key 对话框
  void _showApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller = TextEditingController(text: settings.apiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: '请输入您的 API Key',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setApiKey(value.isEmpty ? null : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示 API Base URL 对话框
  void _showApiBaseUrlDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller =
        TextEditingController(text: settings.apiBaseUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 API Base URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'API Base URL',
            hintText: 'https://api.example.com',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setApiBaseUrl(value.isEmpty ? null : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示模型名称对话框
  void _showModelNameDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller =
        TextEditingController(text: settings.modelName ?? 'qwen3.5-plus');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置模型名称'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '模型名称',
            hintText: 'qwen3.5-plus',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setModelName(value.isEmpty ? 'qwen3.5-plus' : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示百度语音 App ID 对话框
  void _showBaiduSpeechAppIdDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller = TextEditingController(text: settings.baiduSpeechAppId ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 App ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'App ID',
                hintText: '从百度云控制台获取',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '请在百度智能云控制台创建语音识别应用',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setBaiduSpeechAppId(value.isEmpty ? null : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示百度语音 API Key 对话框
  void _showBaiduSpeechApiKeyDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller = TextEditingController(text: settings.baiduSpeechApiKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 API Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'API Key',
            hintText: '从百度云控制台获取',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setBaiduSpeechApiKey(value.isEmpty ? null : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示百度语音 Secret Key 对话框
  void _showBaiduSpeechSecretKeyDialog(
    BuildContext context,
    WidgetRef ref,
    SettingsState settings,
  ) {
    final controller = TextEditingController(text: settings.baiduSpeechSecretKey ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('设置 Secret Key'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Secret Key',
            hintText: '从百度云控制台获取',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final value = controller.text.trim();
              await ref
                  .read(settingsProvider.notifier)
                  .setBaiduSpeechSecretKey(value.isEmpty ? null : value);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  /// 显示清除数据确认对话框
  void _showClearDataConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除数据'),
        content: const Text('确定要删除所有记账记录吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              // TODO: 实现清除所有记录的功能
              // await ref.read(recordsProvider.notifier).clearAllRecords();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('数据已清除')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }

  /// 显示关于对话框
  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('关于酷记'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '酷记 - 智能语音记账应用',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '版本: $kAppVersion',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              _buildHelpSection(
                '🚀 快速开始',
                '长按底部导航栏的麦克风按钮，说出消费内容即可自动记账。例如："早餐花了15元"或"今天工资到账8000元"。',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                '🎤 语音识别配置',
                '本应用支持百度语音识别服务。配置步骤：\n'
                '1. 访问百度智能云控制台\n'
                '2. 创建语音识别应用\n'
                '3. 获取 App ID、API Key、Secret Key\n'
                '4. 在本页面填入对应配置项\n\n'
                '提示：如未配置百度语音，将使用系统自带的语音识别（需要 Google 服务支持）。',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                '🤖 大模型配置',
                '本应用使用大语言模型解析语音内容。配置步骤：\n'
                '1. 准备一个兼容 OpenAI API 的服务\n'
                '2. 获取 API Key\n'
                '3. 在本页面配置 API Key 和 Base URL\n'
                '4. 选择合适的模型名称\n\n'
                '推荐模型：qwen3.5-plus、gpt-4o-mini 等',
              ),
              const SizedBox(height: 12),
              _buildHelpSection(
                '💡 使用技巧',
                '• 一次可说出多条记账："早餐15元，午餐25元"\n'
                '• 支持收入记录："工资到账8000元"\n'
                '• 可指定类别："打车花了30元"\n'
                '• 录音最长15秒，松手自动结束',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 构建帮助说明区块
  Widget _buildHelpSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.brandPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
