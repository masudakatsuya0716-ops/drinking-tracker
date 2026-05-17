# Drinking Tracker

休肝日・飲酒記録アプリ（Flutter）

毎日の飲酒量と休肝日を 5 秒で記録し、月カレンダーで「いつ・どれだけ飲んだか」「いつ休肝したか」を一目で振り返るためのスマホアプリ。完全ローカル保存・通信なし。

詳細は [docs/SPEC.md](docs/SPEC.md) を参照。

## クイックスタート

```bash
flutter pub get
flutter run -d chrome     # ブラウザで起動（最速）
flutter run -d <device>   # 実機 / シミュレータ
```

## 開発

```bash
flutter analyze
flutter test
flutter build web
flutter build apk         # Android
flutter build ios         # iOS（Mac + Xcode）
```

## 技術スタック

- Flutter 3.41 系 / Dart 3.11
- 状態管理: flutter_riverpod 3.x（AsyncNotifier）
- 永続化: shared_preferences（ローカルのみ）
- グラフ: fl_chart
- 日本語化: intl + flutter_localizations

## ディレクトリ構成

```
lib/
├── main.dart
├── drink_record.dart        # データ型
├── drink_repository.dart    # 永続化 + Riverpod
├── stats.dart               # 統計（純粋関数）
├── home_screen.dart         # 3 タブ統合
└── widgets/
    ├── month_calendar.dart  # 月カレンダー（メイン画面）
    ├── drink_form.dart      # 入力フォーム（追加・編集兼用）
    ├── record_tile.dart     # 一覧の 1 行
    ├── stats_card.dart      # 統計指標カード
    └── chart_view.dart      # バーチャート
test/
├── stats_test.dart          # 統計関数
└── widget_test.dart         # タブ・空表示
docs/
└── SPEC.md                  # 仕様書
```
