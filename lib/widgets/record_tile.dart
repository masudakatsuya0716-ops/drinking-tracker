import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../drink_record.dart';
import '../drink_repository.dart';

class RecordTile extends ConsumerWidget {
  final DrinkRecord record;
  final VoidCallback onEdit;

  const RecordTile({
    super.key,
    required this.record,
    required this.onEdit,
  });

  Future<bool> _confirmDelete(BuildContext context, String dateStr) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除しますか?'),
        content: Text('$dateStr の記録を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('キャンセル'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateStr = DateFormat('M/d (E)', 'ja_JP').format(record.date);
    return ListTile(
      onTap: onEdit,
      leading: Icon(
        record.isRestDay ? Icons.local_florist : Icons.local_bar,
        color: record.isRestDay ? Colors.green : Colors.orange,
      ),
      title: Text(
        record.isRestDay
            ? '$dateStr  休肝日'
            : '$dateStr  ${record.type.label} ${record.amountMl} ml',
      ),
      subtitle: record.memo != null ? Text(record.memo!) : null,
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline),
        tooltip: '削除',
        onPressed: () async {
          final ok = await _confirmDelete(context, dateStr);
          if (ok) {
            await ref
                .read(drinkRecordsProvider.notifier)
                .delete(record.id);
          }
        },
      ),
    );
  }
}
