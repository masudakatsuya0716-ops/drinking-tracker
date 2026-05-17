import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../drink_record.dart';
import '../drink_repository.dart';

class DrinkForm extends ConsumerStatefulWidget {
  final DrinkRecord? initial;
  final DateTime? defaultDate;
  final VoidCallback? onSubmitted;
  final bool showDateLabel;

  const DrinkForm({
    super.key,
    this.initial,
    this.defaultDate,
    this.onSubmitted,
    this.showDateLabel = true,
  });

  @override
  ConsumerState<DrinkForm> createState() => _DrinkFormState();
}

class _DrinkFormState extends ConsumerState<DrinkForm> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _selectedDate;
  late DrinkType _type;
  late bool _isRestDay;
  late final TextEditingController _amountController;
  late final TextEditingController _memoController;
  final FocusNode _amountFocus = FocusNode();
  final FocusNode _memoFocus = FocusNode();

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _selectedDate =
        init?.date ?? widget.defaultDate ?? DateTime.now();
    _type = init?.type ?? DrinkType.beer;
    _isRestDay = init?.isRestDay ?? false;
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

  Future<void> _pickDate() async {
    FocusScope.of(context).unfocus();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
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
        DateFormat('yyyy/MM/dd (E)', 'ja_JP').format(_selectedDate);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.showDateLabel)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('日付'),
              subtitle: Text(dateLabel),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                dateLabel,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('休肝日'),
            value: _isRestDay,
            onChanged: (v) {
              FocusScope.of(context).unfocus();
              setState(() => _isRestDay = v);
            },
          ),
          if (!_isRestDay) ...[
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
            const SizedBox(height: 8),
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
          const SizedBox(height: 8),
          TextFormField(
            controller: _memoController,
            focusNode: _memoFocus,
            decoration: const InputDecoration(
              labelText: 'メモ (任意)',
            ),
            maxLength: 200,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _submit,
              icon: Icon(_isEdit ? Icons.check : Icons.save),
              label: Text(_isEdit ? '更新する' : '記録する'),
            ),
          ),
        ],
      ),
    );
  }
}
