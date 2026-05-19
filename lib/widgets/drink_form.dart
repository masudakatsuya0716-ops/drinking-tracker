import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../drink_record.dart';
import '../drink_repository.dart';
import '../theme.dart';

class DrinkForm extends ConsumerStatefulWidget {
  final DrinkRecord? initial;
  final DateTime? defaultDate;
  final VoidCallback? onSubmitted;

  const DrinkForm({
    super.key,
    this.initial,
    this.defaultDate,
    this.onSubmitted,
  });

  @override
  ConsumerState<DrinkForm> createState() => _DrinkFormState();
}

class _DrinkFormState extends ConsumerState<DrinkForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late DrinkType _type;
  late bool _isRestDay;
  bool _statusChosen = false;
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedDate = init?.date ?? widget.defaultDate ?? DateTime.now();
    _type = init?.type ?? DrinkType.beer;
    _isRestDay = init?.isRestDay ?? false;
    _statusChosen = init != null;
    _amountController = TextEditingController(
      text: (init != null && !init.isRestDay && init.amountMl > 0)
          ? init.amountMl.toString()
          : '',
    );
    _memoController = TextEditingController(text: init?.memo ?? '');
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    _amountFocus.dispose();
    _memoFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_statusChosen) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('まず「お酒は?」を選んでください')),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final amountMl =
        _isRestDay ? 0 : int.parse(_amountController.text.trim());
    final memoRaw = _memoController.text.trim();
    final memo = memoRaw.isEmpty ? null : memoRaw;

    final notifier = ref.read(drinkRecordsProvider.notifier);
    final messenger = ScaffoldMessenger.of(context);

    if (_isEdit) {
      final updated = widget.initial!.copyWith(
        date: _selectedDate,
        amountMl: amountMl,
        type: _type,
        isRestDay: _isRestDay,
        memo: memo,
        clearMemo: memo == null,
      );
      await notifier.updateRecord(updated);
    } else {
      final record = DrinkRecord(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        date: _selectedDate,
        amountMl: amountMl,
        type: _type,
        isRestDay: _isRestDay,
        memo: memo,
      );
      await notifier.add(record);
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(_isEdit ? '更新しました' : '記録しました')),
    );
    widget.onSubmitted?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('M月d日 (E)', 'ja_JP').format(_selectedDate);
    final isToday =
        DateUtils.isSameDay(_selectedDate, DateTime.now());

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              isToday ? '今日の記録' : '日付の記録',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.inkSoft,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Text(
              dateLabel,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
                letterSpacing: -0.5,
                height: 1.2,
              ),
            ),
          ),
          const Text(
            'お酒は?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          _StatusChoice(
            label: '飲まなかった',
            sub: '休肝を守れた',
            color: AppColors.primary,
            ink: AppColors.primaryInk,
            selected: _statusChosen && _isRestDay,
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() {
                _isRestDay = true;
                _statusChosen = true;
              });
            },
          ),
          const SizedBox(height: 10),
          _StatusChoice(
            label: '飲んだ',
            sub: '正直に記録する',
            color: AppColors.danger,
            ink: Colors.white,
            selected: _statusChosen && !_isRestDay,
            onTap: () {
              setState(() {
                _isRestDay = false;
                _statusChosen = true;
              });
            },
          ),
          if (_statusChosen && !_isRestDay) ...[
            const SizedBox(height: 24),
            const Text(
              'どのくらい飲みましたか?',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _amountController,
              focusNode: _amountFocus,
              decoration: const InputDecoration(
                labelText: '量 (ml)',
                hintText: '350',
              ),
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              onFieldSubmitted: (_) => _memoFocus.requestFocus(),
              validator: (v) {
                if (_isRestDay) return null;
                final t = (v ?? '').trim();
                if (t.isEmpty) return '量を入力してください';
                final n = int.tryParse(t);
                if (n == null) return '数字を入力してください';
                if (n <= 0) return '1 以上を入力してください';
                if (n > 5000) return '5000 以下にしてください';
                return null;
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<DrinkType>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: '種類'),
              items: DrinkType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _type = v);
              },
            ),
          ],
          if (_statusChosen) ...[
            const SizedBox(height: 24),
            const Text(
              'ひとこと (任意)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _memoController,
              focusNode: _memoFocus,
              decoration: const InputDecoration(
                hintText: '気づいたこと、気持ちなど',
              ),
              maxLength: 200,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submit,
              child: Text(
                _isEdit ? 'この日の記録を更新' : 'この日の記録を保存',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChoice extends StatelessWidget {
  final String label;
  final String sub;
  final Color color;
  final Color ink;
  final bool selected;
  final VoidCallback onTap;

  const _StatusChoice({
    required this.label,
    required this.sub,
    required this.color,
    required this.ink,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color : AppColors.surface;
    final fg = selected ? ink : AppColors.ink;
    final subFg = selected
        ? ink.withValues(alpha: 0.9)
        : AppColors.inkSoft;
    final borderColor = selected ? color : AppColors.border;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(18),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          constraints: const BoxConstraints(minHeight: 80),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : Colors.transparent,
                  border: Border.all(
                    color: selected ? Colors.white : AppColors.border,
                    width: 2,
                  ),
                ),
                alignment: Alignment.center,
                child: selected
                    ? Container(
                        width: 14,
                        height: 14,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: fg,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 13,
                        color: subFg,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
