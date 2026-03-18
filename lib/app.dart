import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/utils/permission_utils.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/statistics/statistics_screen.dart';
import 'presentation/screens/settings/settings_screen.dart';
import 'presentation/widgets/manual_entry_sheet.dart';
import 'presentation/widgets/voice_button_nav.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: '酷记',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const MainNavigationScreen(),
    );
  }
}

/// 主导航屏幕，包含底部导航栏
/// 导航栏布局: [首页] [统计] [语音按钮] [记账] [设置]
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentIndex = 0;

  // 页面索引映射:
  // 0: 首页
  // 1: 统计
  // 2: 设置
  final List<Widget> _screens = [
    const HomeScreen(),
    const StatisticsScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // 应用启动时检查麦克风权限
    _checkMicrophonePermission();
  }

  /// 检查麦克风权限
  /// 应用启动时自动调用，无权限则弹窗引导
  void _checkMicrophonePermission() async {
    // 延迟一点执行，确保页面已经构建完成
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      await PermissionUtils.checkAndRequestPermission(context);
    }
  }

  /// 处理导航项点击
  /// 索引映射:
  /// - 0: 首页 -> _screens[0]
  /// - 1: 统计 -> _screens[1]
  /// - 2: 语音按钮 -> 不切换页面，只触发录音
  /// - 3: 记账 -> 显示手动记账表单
  /// - 4: 设置 -> _screens[2]
  void _onNavItemTap(int navIndex) {
    // 语音按钮 (索引 2) - 不切换页面
    if (navIndex == 2) {
      return;
    }

    // 记账按钮 (索引 3) - 显示手动记账表单
    if (navIndex == 3) {
      showManualEntrySheet(context);
      return;
    }

    // 设置按钮 (索引 4) -> _screens[2]
    if (navIndex == 4) {
      setState(() => _currentIndex = 2);
      return;
    }

    // 首页 (索引 0) -> _screens[0]
    // 统计 (索引 1) -> _screens[1]
    setState(() => _currentIndex = navIndex);
  }

  /// 检查导航项是否选中
  bool _isNavItemSelected(int navIndex) {
    // 首页
    if (navIndex == 0 && _currentIndex == 0) return true;
    // 统计
    if (navIndex == 1 && _currentIndex == 1) return true;
    // 设置
    if (navIndex == 4 && _currentIndex == 2) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 首页 (导航索引 0)
                _buildNavItem(
                  Icons.home_outlined,
                  Icons.home,
                  '首页',
                  0,
                ),
                // 统计 (导航索引 1)
                _buildNavItem(
                  Icons.pie_chart_outline,
                  Icons.pie_chart,
                  '统计',
                  1,
                ),
                // 语音按钮 (导航索引 2)
                const VoiceButtonNav(),
                // 记账 (导航索引 3)
                _buildNavItem(
                  Icons.edit_outlined,
                  Icons.edit,
                  '记账',
                  3,
                ),
                // 设置 (导航索引 4)
                _buildNavItem(
                  Icons.settings_outlined,
                  Icons.settings,
                  '设置',
                  4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int navIndex,
  ) {
    final isSelected = _isNavItemSelected(navIndex);
    return InkWell(
      onTap: () => _onNavItemTap(navIndex),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
