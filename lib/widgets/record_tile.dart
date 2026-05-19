import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../drink_record.dart';
import '../drink_repository.dart';
import '../theme.dart';

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
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text('削除しますか?'),
        content: Text('$dateStr の記録を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            style: TextButton.styleFrom(foregroundColor: AppColors.inkSoft),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
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
    final color = record.isRestDay ? AppColors.primary : AppColors.danger;
    final statusLabel = record.isRestDay ? '飲まなかった' : '飲んだ';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${record.date.day}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 13,
                            color: color,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.isRestDay
                          ? '休肝日'
                          : '${record.type.label}  ${record.amountMl} ml',
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (record.memo != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        record.memo!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: AppColors.inkMuted,
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
            ],
          ),
        ),
      ),
    );
  }
}
