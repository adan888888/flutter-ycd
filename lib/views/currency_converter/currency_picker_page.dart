import 'package:flutter/material.dart';

import 'currency_converter_controller.dart';

/// 底部弹窗选择币种：顶部标题 + 模糊搜索 + 列表
class CurrencyPickerSheet extends StatefulWidget {
  const CurrencyPickerSheet({
    super.key,
    required this.currencies,
    required this.selectedCode,
    this.title = '选择币种',
  });

  final List<Map<String, dynamic>> currencies;
  final String selectedCode;
  final String title;

  /// 弹出底部 sheet，选中后返回币种代码；取消返回 `null`
  static Future<String?> show(
    BuildContext context, {
    required List<Map<String, dynamic>> currencies,
    required String selectedCode,
    String title = '选择币种',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (ctx) {
        final viewInsets = MediaQuery.viewInsetsOf(ctx).bottom;
        final h = MediaQuery.sizeOf(ctx).height * 0.72;
        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets),
          child: SizedBox(
            height: h,
            child: SafeArea(
              top: false,
              child: CurrencyPickerSheet(
                currencies: currencies,
                selectedCode: selectedCode,
                title: title,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  State<CurrencyPickerSheet> createState() => _CurrencyPickerSheetState();
}

class _CurrencyPickerSheetState extends State<CurrencyPickerSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _searchController.text;
    if (q.trim().isEmpty) {
      return List<Map<String, dynamic>>.from(widget.currencies);
    }
    return widget.currencies.where((c) => CurrencyConverterController.currencyMatchesQuery(c, q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 4, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                tooltip: '关闭',
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '模糊搜索币种（代码或中文名）',
              prefixIcon: const Icon(Icons.search, size: 22),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      tooltip: '清除',
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              final list = _filtered;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    '无匹配币种',
                    style: TextStyle(color: Colors.grey[600], fontSize: 15),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: list.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey[200]),
                itemBuilder: (context, index) {
                  final c = list[index];
                  final code = c['code'] as String;
                  final selected = code == widget.selectedCode;
                  return ListTile(
                    leading: Text('${c['flag']}', style: const TextStyle(fontSize: 22)),
                    title: Text(
                      code,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      '${c['name']}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                    trailing: selected ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary) : null,
                    onTap: () => Navigator.pop(context, code),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
