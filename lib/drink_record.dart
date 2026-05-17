enum DrinkType {
  beer('ビール'),
  sake('日本酒'),
  wine('ワイン'),
  shochu('焼酎'),
  whisky('ウイスキー'),
  other('その他');

  const DrinkType(this.label);
  final String label;
}

class DrinkRecord {
  final String id;
  final DateTime date;
  final int amountMl;
  final DrinkType type;
  final bool isRestDay;
  final String? memo;

  const DrinkRecord({
    required this.id,
    required this.date,
    required this.amountMl,
    required this.type,
    required this.isRestDay,
    this.memo,
  });

  DrinkRecord copyWith({
    DateTime? date,
    int? amountMl,
    DrinkType? type,
    bool? isRestDay,
    String? memo,
    bool clearMemo = false,
  }) {
    return DrinkRecord(
      id: id,
      date: date ?? this.date,
      amountMl: amountMl ?? this.amountMl,
      type: type ?? this.type,
      isRestDay: isRestDay ?? this.isRestDay,
      memo: clearMemo ? null : (memo ?? this.memo),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'amountMl': amountMl,
        'type': type.name,
        'isRestDay': isRestDay,
        'memo': memo,
      };

  factory DrinkRecord.fromJson(Map<String, dynamic> json) => DrinkRecord(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        amountMl: json['amountMl'] as int,
        type: DrinkType.values.byName(json['type'] as String),
        isRestDay: json['isRestDay'] as bool,
        memo: json['memo'] as String?,
      );
}
