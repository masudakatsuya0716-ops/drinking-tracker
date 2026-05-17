# Drinking Tracker 仕様書

最終更新: 2026-05-18

---

## 1. アプリ概要

### 1.1 名称
Drinking Tracker（休肝日・飲酒記録アプリ）

### 1.2 目的
毎日の飲酒量と休肝日を 5 秒で記録し、月単位のカレンダーで「いつ・どれだけ飲んだか」「いつ休肝したか」を一目で振り返るためのスマートフォンアプリ。

### 1.3 対象ユーザー
- 自分の飲酒習慣を可視化したい個人
- 休肝日を継続的に意識したい人

### 1.4 主な特徴
- ファーストビューが月カレンダー。1ヶ月分の飲酒・休肝状況がカラーで俯瞰できる
- 日付をタップしてその日の入力画面（モーダル）に遷移
- 連続休肝日・直近7日合計・今月の休肝日数を常時表示
- ローカル保存のみ（SharedPreferences）。認証・通信なし
- iOS / Android 両対応（Flutter）

---

## 2. ロール

| ロール | 識別方法 | 権限 |
|---|---|---|
| 一般ユーザー | 認証なし、端末ローカル | 全機能 |

データは端末ローカルに閉じる。複数端末同期・他人との共有は対象外。

---

## 3. 機能仕様

### 3.1 画面一覧

| ID | 画面名 | 種別 | コンポーネント |
|---|---|---|---|
| S1 | カレンダー | タブ | `_CalendarTab`（`MonthCalendar`） |
| S2 | 一覧 | タブ | `_ListTab`（`RecordTile`） |
| S3 | グラフ | タブ | `_ChartTab`（`ChartView`） |
| S4 | 日次入力 | モーダル | `DrinkForm` |

### 3.2 画面遷移

```
[起動]
  ▼
[S1 カレンダー] ◀───────┐
   │  日付タップ        │
   ▼                  │ 保存/キャンセル
[S4 日次入力 (Sheet)] ──┘

[S1] ──タブ切替──▶ [S2 一覧] ──項目タップ──▶ [S4]
[S1] ──タブ切替──▶ [S3 グラフ]
```

### 3.3 機能詳細

#### F-1 月カレンダー表示（S1）
- 表示: 当月の日曜起点グリッド（最大 6 行 × 7 列）
- 各日付セル: 日番号 + 記録状態の視覚化
  - 飲酒記録あり: オレンジ背景 + 量(ml) 表示
  - 休肝日記録あり: 緑背景 + 花アイコン
  - 記録なし: 薄い枠線のみ
- 今日: 太枠でハイライト
- 未来日: タップ不可・グレーアウト
- 月ナビゲーション: ヘッダーの ◀ / ▶ で前月・翌月

#### F-2 日次入力モーダル（S4）
- 起動: S1 カレンダーで日付タップ、または S2 一覧で項目タップ
- 入力項目:
  - 日付（モーダル冒頭に表示。S1 タップ時はその日固定）
  - 休肝日トグル（ON で量・種類欄が非表示）
  - 量 (ml): 1〜5000 の整数。バリデーション付き
  - 種類: ビール / 日本酒 / ワイン / 焼酎 / ウイスキー / その他
  - メモ: 任意、最大 200 文字
- 動作:
  - 既存記録がある日: 編集モード（「更新する」）
  - 記録がない日: 追加モード（「記録する」）
  - 保存後: モーダルを閉じ、カレンダー/一覧を即時反映

#### F-3 統計表示（全タブ共通）
- 連続休肝日: 直近の連続した休肝日数。最新日が飲酒 or 記録なしなら 0
- 直近 7 日: 今日を含む過去 7 日間の合計 ml
- 今月の休肝日: 当月の休肝日数（同日重複は 1 として数える）

#### F-4 一覧表示（S2）
- 日付降順で全記録を表示
- 各項目: 日付 / 種類 + 量（or 「休肝日」表記）/ メモ
- 操作:
  - タップ → 編集モーダル（S4）
  - ゴミ箱 → 削除確認ダイアログ → 削除

#### F-5 グラフ表示（S3）
- 直近 14 日の日次飲酒量をバーチャート（fl_chart）
- 色分け: 飲酒(オレンジ) / 休肝日(緑、最小高さ) / 記録なし(グレー)
- ツールチップ: バーをタップで日付と内訳

#### F-6 バリデーション・入力支援
- 量: 空 / 非数値 / 0 以下 / 5000 超 で個別エラーメッセージ
- 量入力 → メモへフォーカス移動（textInputAction.next）
- メモ確定で送信、または明示的に「記録する」ボタン
- 日付選択ダイアログを開く際は IME を閉じる

---

## 4. データモデル

### 4.1 永続化先

`SharedPreferences` の単一キー `drink_records_v1` に、JSON 文字列として配列を保存。

### 4.2 型定義（Dart）

```dart
enum DrinkType { beer, sake, wine, shochu, whisky, other }

class DrinkRecord {
  final String id;          // microsecondsSinceEpoch ベース
  final DateTime date;      // 記録対象日
  final int amountMl;       // 飲酒量。休肝日は 0
  final DrinkType type;     // 種類
  final bool isRestDay;     // 休肝日フラグ
  final String? memo;       // 任意メモ
}
```

### 4.3 JSON 形式

```json
{
  "id": "1747512345678901",
  "date": "2026-05-18T00:00:00.000",
  "amountMl": 350,
  "type": "beer",
  "isRestDay": false,
  "memo": "晩酌"
}
```

### 4.4 同日複数レコードの扱い

- 仕様上は 1 日 1 レコード前提
- 実装上は許容（旧データ・誤入力対策）
- カレンダー表示は ID 降順で最新を採用
- 統計集計は全件加算（飲酒量）/ 全件休肝判定（休肝日数）

---

## 5. 主要モジュール仕様

### 5.1 [lib/drink_record.dart](../lib/drink_record.dart) — データ型

| シンボル | 種別 | 説明 |
|---|---|---|
| `DrinkType` | enum | 飲料種別（label 付き） |
| `DrinkRecord` | class | 1 レコードのデータ型 |
| `DrinkRecord.copyWith` | method | 編集時の差分更新 |
| `DrinkRecord.toJson` / `fromJson` | method | 永続化用シリアライズ |

### 5.2 [lib/drink_repository.dart](../lib/drink_repository.dart) — 永続化と状態管理

| シンボル | 種別 | 説明 |
|---|---|---|
| `DrinkRepository` | class | SharedPreferences の CRUD ラッパー |
| `.loadAll()` | method | 全件取得 |
| `.add(record)` | method | 1 件追加 |
| `.update(record)` | method | id で 1 件更新 |
| `.delete(id)` | method | id で 1 件削除 |
| `drinkRepositoryProvider` | Provider | DI 用 |
| `DrinkRecordsNotifier` | AsyncNotifier | レコード一覧の状態保持 |
| `.add` / `.updateRecord` / `.delete` | method | 永続化 + state 再評価 |
| `drinkRecordsProvider` | AsyncNotifierProvider | UI からの購読窓口 |

※ `AsyncNotifier` 組み込みの `update` メソッドと衝突するため、Notifier 側のメソッド名は `updateRecord` とする。

### 5.3 [lib/stats.dart](../lib/stats.dart) — 統計（純粋関数）

| 関数 | 引数 | 返り値 | 説明 |
|---|---|---|---|
| `restDayStreak(records)` | List<DrinkRecord> | int | 連続休肝日数 |
| `last7DaysTotalMl(records, {now})` | List, DateTime? | int | 直近 7 日の合計 ml |
| `monthlyRestDays(records, {now})` | List, DateTime? | int | 当月の休肝日数 |
| `dailyAggregates(records, days, {now})` | List, int, DateTime? | List<DailyAggregate> | N 日分の日次集計 |

すべて `now` を注入可能 → テスト容易。

### 5.4 [lib/widgets/](../lib/widgets) — UI コンポーネント

| ファイル | 役割 |
|---|---|
| `month_calendar.dart` | 月カレンダーグリッド + 月ナビゲーション |
| `drink_form.dart` | 追加・編集兼用フォーム（バリデーション + フォーカス管理） |
| `record_tile.dart` | 一覧の 1 行（タップで編集 / 削除確認ダイアログ） |
| `stats_card.dart` | 連続休肝日 / 直近 7 日 / 今月休肝日の 3 指標カード |
| `chart_view.dart` | fl_chart による日次バーチャート |

### 5.5 [lib/home_screen.dart](../lib/home_screen.dart) — タブ統合

3 タブ（カレンダー / 一覧 / グラフ）の構成と、日次入力モーダル `_showDaySheet` を持つ。

---

## 6. 非機能要件

| 項目 | 内容 |
|---|---|
| **対応 OS** | iOS / Android（Flutter 3.41 系で動作確認）|
| **言語** | 日本語のみ |
| **オフライン** | 完全ローカル動作。通信なし |
| **同期** | なし（端末ローカルに閉じる） |
| **データ量上限** | メモ 200 文字、量 5000 ml/レコード。レコード数の上限は設けない |
| **アクセシビリティ** | tooltip 設定済み。スクリーンリーダー対応は最低限 |
| **パフォーマンス** | 数百件規模を想定。それ以上は Drift/Isar への移行を検討 |

---

## 7. システム構成

```
[ユーザー端末 (iOS / Android)]
   │ Flutter アプリ
   ▼
[Flutter Engine]
   │
   ▼
[SharedPreferences (端末ローカル)]
```

外部通信・サーバー・クラウドは一切なし。

### 7.1 主要技術スタック

| レイヤー | 技術 | バージョン |
|---|---|---|
| 言語 | Dart | 3.11.x |
| フレームワーク | Flutter | 3.41 系 stable |
| 状態管理 | flutter_riverpod | ^3.3.1 |
| 永続化 | shared_preferences | ^2.5.5 |
| グラフ | fl_chart | ^1.2.0 |
| 日付/地域化 | intl + flutter_localizations | ^0.20.2 |
| テスト | flutter_test | （SDK 同梱） |

---

## 8. セキュリティ

- データは端末ローカルにのみ保存（SharedPreferences）
- 外部送信・認証・トラッキングなし
- 個人情報・健康情報は端末内に留まる
- アンインストールするとデータは失われる（バックアップ機能は将来検討）

---

## 9. 運用

### 9.1 開発環境セットアップ

```bash
cd projects/drinking_tracker
flutter pub get
flutter analyze
flutter test
flutter run -d chrome     # ブラウザで起動
flutter run -d <device>   # 実機 / シミュレータ
```

### 9.2 ビルド

```bash
flutter build apk         # Android
flutter build ios         # iOS（Mac + Xcode 必要）
flutter build web         # Web
```

### 9.3 トラブルシューティング

| 症状 | 原因 / 対処 |
|---|---|
| `Locale data has not been initialized` | テスト先頭で `initializeDateFormatting('ja_JP')` を呼ぶ |
| `DrinkRecordsNotifier.update` で型エラー | Riverpod 3.x の `AsyncNotifier` に組み込み `update` がある。`updateRecord` を使用 |
| DatePicker が英語表示 | `MaterialApp.localizationsDelegates` に `GlobalMaterialLocalizations.delegate` 等を設定する |

---

## 10. テスト

### 10.1 ユニットテスト

- 対象: [lib/stats.dart](../lib/stats.dart)
- ファイル: [test/stats_test.dart](../test/stats_test.dart)
- ケース: 連続休肝日 / 直近 7 日合計 / 今月休肝日 / 日次集計

### 10.2 ウィジェットテスト

- 対象: タブ切替・空状態・凡例表示
- ファイル: [test/widget_test.dart](../test/widget_test.dart)
- 前提: `SharedPreferences.setMockInitialValues({})` と `initializeDateFormatting('ja_JP')`

### 10.3 実行

```bash
flutter test
```

---

## 11. 将来の検討事項

| 項目 | メモ |
|---|---|
| 目標設定（週 N 日休肝） | 設定画面 + 達成バナー |
| 通知（休肝日リマインド） | flutter_local_notifications を使用 |
| クラウド同期 | Firebase or Supabase。複数端末対応。要認証 |
| エクスポート / インポート | CSV 形式。バックアップと機種変更対応 |
| ローカル DB 移行 | レコード数 1000 件超で Drift / Isar 検討 |
| グラフ拡張 | 月次推移、種類別比率、連続休肝の履歴 |
| ストア公開 | Google Play 先行 → iOS。プライバシーポリシー必須 |
| ダークモード対応強化 | 現状は ColorScheme.fromSeed 任せ。カレンダー色など見直し |

---

## 12. 変更履歴

| 日付 | 内容 |
|---|---|
| 2026-05-17 | 初期実装（フォーム + 一覧、SharedPreferences、Riverpod） |
| 2026-05-17 | 編集・グラフ・統計・バリデーション拡張 |
| 2026-05-18 | ファーストビューを月カレンダーに変更、3 タブ構成、仕様書作成 |
