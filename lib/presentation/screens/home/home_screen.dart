import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_bookkeeping_provider.dart';
import '../../widgets/batch_confirmation_card.dart';
import '../../widgets/record_list_widget.dart';
import '../../widgets/weekly_summary_card.dart';

/// 首页屏幕
/// 显示本周记账记录列表、统计卡片和语音记账入口
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听批量确认卡片触发器
    ref.listen<bool>(showBatchConfirmationTriggerProvider, (previous, next) {
      if (next == true) {
        // 重置触发器
        ref.read(showBatchConfirmationTriggerProvider.notifier).state = false;
        // 显示批量确认弹窗
        showBatchConfirmationCard(context);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('酷记'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 本周统计卡片
          const WeeklySummaryCard(),

          // 记录列表
          const Expanded(
            child: RecordListWidget(),
          ),
        ],
      ),
    );
  }
}
