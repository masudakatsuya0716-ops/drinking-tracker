import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'drink_record.dart';

const _kStorageKey = 'drink_records_v1';

class DrinkRepository {
  Future<List<DrinkRecord>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kStorageKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => DrinkRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAll(List<DrinkRecord> records) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        jsonEncode(records.map((r) => r.toJson()).toList());
    await prefs.setString(_kStorageKey, encoded);
  }

  Future<void> add(DrinkRecord record) async {
    final records = await loadAll();
    records.add(record);
    await _saveAll(records);
  }

  Future<void> update(DrinkRecord record) async {
    final records = await loadAll();
    final i = records.indexWhere((r) => r.id == record.id);
    if (i < 0) return;
    records[i] = record;
    await _saveAll(records);
  }

  Future<void> delete(String id) async {
    final records = await loadAll();
    records.removeWhere((r) => r.id == id);
    await _saveAll(records);
  }
}

final drinkRepositoryProvider =
    Provider<DrinkRepository>((ref) => DrinkRepository());

class DrinkRecordsNotifier extends AsyncNotifier<List<DrinkRecord>> {
  @override
  Future<List<DrinkRecord>> build() {
    return ref.read(drinkRepositoryProvider).loadAll();
  }

  Future<void> add(DrinkRecord record) async {
    await ref.read(drinkRepositoryProvider).add(record);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateRecord(DrinkRecord record) async {
    await ref.read(drinkRepositoryProvider).update(record);
    ref.invalidateSelf();
    await future;
  }

  Future<void> delete(String id) async {
    await ref.read(drinkRepositoryProvider).delete(id);
    ref.invalidateSelf();
    await future;
  }
}

final drinkRecordsProvider =
    AsyncNotifierProvider<DrinkRecordsNotifier, List<DrinkRecord>>(
  DrinkRecordsNotifier.new,
);
