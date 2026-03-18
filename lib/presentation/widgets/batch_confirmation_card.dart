import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/parsed_result.dart';
import '../providers/voice_bookkeeping_provider.dart';
import 'record_edit_item.dart';

/// 批量记账确认弹窗
/// 分页显示多条记录，支持展开式编辑
class BatchConfirmationCard extends ConsumerStatefulWidget {
  const BatchConfirmationCard({super.key});

  @override
  ConsumerState<BatchConfirmationCard> createState() => _BatchConfirmationCardState();
}

class _BatchConfirmationCardState extends ConsumerState<BatchConfirmationCard> {
  late List<ParsedResult> _results;
  late List<bool> _expandedStates;
  int _currentIndex = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _results = List.from(ref.read(parsedResultsProvider));
    _expandedStates = List.filled(_results.length, false);
    // 默认展开第一条
    if (_expandedStates.isNotEmpty) {
      _expandedStates[0] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = _results.length;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部指示条和标题
            _buildHeader(totalCount),
            
            // 分页指示器
            if (totalCount > 1) _buildPageIndicator(totalCount),
            
            const SizedBox(height: 16),
            
            // 记录编辑区域
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildRecordEditArea(),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 添加按钮
            _buildAddButton(),
            
            const SizedBox(height: 16),
            
            // 底部按钮
            _buildBottomButtons(),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// 构建顶部标题栏
  Widget _buildHeader(int totalCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // 指示条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Spacer(),
          // 标题
          Text(
            '确认记账 (共$totalCount条)',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          // 关闭按钮
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: AppColors.textSecondary),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// 构建分页指示器
  Widget _buildPageIndicator(int totalCount) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount, (index) {
          final isActive = index == _currentIndex;
          return GestureDetector(
            onTap: () => _switchToPage(index),
            child: Container(
              width: isActive ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandPrimary : AppColors.divider,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// 构建记录编辑区域
  Widget _buildRecordEditArea() {
    if (_results.isEmpty) {
      return const Center(
        child: Text('没有待确认的记录'),
      );
    }

    // 显示当前页的记录
    return Column(
      children: [
        // 当前记录编辑项
        RecordEditItem(
          index: _currentIndex,
          result: _results[_currentIndex],
          isExpanded: _expandedStates[_currentIndex],
          onExpandToggle: () => _toggleExpand(_currentIndex),
          onUpdate: (updated) => _updateResult(_currentIndex, updated),
          onDelete: () => _deleteResult(_currentIndex),
        ),
        
        const SizedBox(height: 16),
        
        // 导航按钮
        if (_results.length > 1) _buildNavigationButtons(),
      ],
    );
  }

  /// 构建导航按钮
  Widget _buildNavigationButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 上一条
        TextButton.icon(
          onPressed: _currentIndex > 0 ? _goToPrevious : null,
          icon: const Icon(Icons.arrow_back_ios, size: 16),
          label: const Text('上一条'),
          style: TextButton.styleFrom(
            foregroundColor: _currentIndex > 0 
                ? AppColors.brandPrimary 
                : AppColors.textDisabled,
          ),
        ),
        const SizedBox(width: 32),
        // 页码显示
        Text(
          '${_currentIndex + 1} / ${_results.length}',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 32),
        // 下一条
        TextButton.icon(
          onPressed: _currentIndex < _results.length - 1 ? _goToNext : null,
          icon: const Text('下一条'),
          label: const Icon(Icons.arrow_forward_ios, size: 16),
          style: TextButton.styleFrom(
            foregroundColor: _currentIndex < _results.length - 1 
                ? AppColors.brandPrimary 
                : AppColors.textDisabled,
          ),
        ),
      ],
    );
  }

  /// 构建添加按钮
  Widget _buildAddButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: OutlinedButton.icon(
        onPressed: _addNewRecord,
        icon: const Icon(Icons.add, size: 20),
        label: const Text('添加一条'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          side: const BorderSide(color: AppColors.brandPrimary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  /// 构建底部按钮
  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // 取消按钮
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                side: const BorderSide(color: AppColors.divider),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('取消'),
            ),
          ),
          const SizedBox(width: 12),
          // 确认保存按钮
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveRecords,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('确认保存'),
            ),
          ),
        ],
      ),
    );
  }

  /// 切换到指定页面
  void _switchToPage(int index) {
    setState(() {
      // 收起当前展开的
      if (_expandedStates[_currentIndex]) {
        _expandedStates[_currentIndex] = false;
      }
      _currentIndex = index;
      // 展开新的当前项
      _expandedStates[_currentIndex] = true;
    });
  }

  /// 展开/收起切换
  void _toggleExpand(int index) {
    setState(() {
      _expandedStates[index] = !_expandedStates[index];
    });
  }

  /// 更新记录
  void _updateResult(int index, ParsedResult updated) {
    setState(() {
      _results[index] = updated;
    });
    // 同步更新 Provider
    ref.read(voiceBookkeepingControllerProvider).updateParsedResults(_results);
  }

  /// 删除记录
  void _deleteResult(int index) {
    setState(() {
      _results.removeAt(index);
      _expandedStates.removeAt(index);
      
      // 调整当前索引
      if (_currentIndex >= _results.length) {
        _currentIndex = _results.length - 1;
      }
      if (_currentIndex >= 0 && _expandedStates.isNotEmpty) {
        _expandedStates[_currentIndex] = true;
      }
    });
    
    // 如果删完了，关闭弹窗
    if (_results.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    
    // 同步更新 Provider
    ref.read(voiceBookkeepingControllerProvider).updateParsedResults(_results);
  }

  /// 添加新记录
  void _addNewRecord() {
    setState(() {
      // 收起当前展开的
      if (_expandedStates.isNotEmpty && _expandedStates[_currentIndex]) {
        _expandedStates[_currentIndex] = false;
      }
      
      // 添加新记录
      _results.add(ParsedResult(
        amount: null,
        category: '其他',
        type: '支出',
        note: '',
        rawText: '',
      ));
      _expandedStates.add(true);
      
      // 切换到新记录
      _currentIndex = _results.length - 1;
    });
    
    // 同步更新 Provider
    ref.read(voiceBookkeepingControllerProvider).updateParsedResults(_results);
  }

  /// 上一条
  void _goToPrevious() {
    if (_currentIndex > 0) {
      _switchToPage(_currentIndex - 1);
    }
  }

  /// 下一条
  void _goToNext() {
    if (_currentIndex < _results.length - 1) {
      _switchToPage(_currentIndex + 1);
    }
  }

  /// 保存所有记录
  Future<void> _saveRecords() async {
    // 验证所有记录
    final invalidRecords = <int>[];
    for (int i = 0; i < _results.length; i++) {
      if (_results[i].amount == null || _results[i].amount! <= 0) {
        invalidRecords.add(i + 1);
      }
    }
    
    if (invalidRecords.isNotEmpty) {
      _showErrorDialog('第 ${invalidRecords.join(', ')} 条记录金额无效');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final controller = ref.read(voiceBookkeepingControllerProvider);
      final result = await controller.saveRecords(_results);

      if (result.isSuccess) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('成功保存 ${result.successCount} 条记录'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        // 显示失败记录
        if (mounted) {
          _showFailedRecordsDialog(result);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('保存失败: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// 显示错误对话框
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  /// 显示失败记录对话框
  void _showFailedRecordsDialog(BatchSaveResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${result.failedRecords.length}条记录保存失败'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: result.failedRecords.length,
            itemBuilder: (context, index) {
              final failed = result.failedRecords[index];
              final parsedResult = failed['result'] as ParsedResult;
              final error = failed['error'] as String;
              return ListTile(
                dense: true,
                title: Text('${parsedResult.note ?? '记录'}: ¥${parsedResult.amount}'),
                subtitle: Text(error, style: const TextStyle(color: AppColors.error)),
              );
            },
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
}

/// 显示批量确认弹窗
Future<void> showBatchConfirmationCard(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    enableDrag: false,
    isDismissible: false,
    builder: (context) => const BatchConfirmationCard(),
  );
}
