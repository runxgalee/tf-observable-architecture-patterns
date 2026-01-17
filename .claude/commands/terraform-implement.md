---
description: Terraform実装とレビューを繰り返し、品質基準を満たすまで修正を続ける
argument-hint: 実装内容を説明（例："event-drivenアーキテクチャにCloud Functionsを追加"）
---

# Terraform Implementation with Review Loop

Terraformコードの新規作成・修正を行い、レビューエージェントで品質確認を行います。
指摘事項があれば修正を繰り返し、すべての基準をパスするまで実装を継続します。

## Task

$ARGUMENTS

## Workflow

### Phase 1: 要件分析
1. 実装対象のスコープを明確化
2. 関連する既存コードを確認
3. 必要なリソースと依存関係を特定

### Phase 2: 実装
1. 新規ファイル作成または既存ファイル修正
2. 命名規則に従う（snake_case, resource_prefix）
3. 標準パターンを適用（common_labels, 変数の説明など）

### Phase 3: レビューループ
以下を繰り返す（**最大5回まで**）:
1. `/terraform-review` でコードをレビュー
2. `coderabbit --prompt-only` を実行してAIレビュープロンプトを取得
3. 指摘事項を確認（terraform-reviewとcoderabbit両方の結果を考慮）
4. 指摘がある場合は修正を実施
5. 再度レビューを実行
6. すべての指摘が解消されるまで繰り返す

**ループ上限に達した場合**:
- 5回のレビューループで解消できなかった場合は終了
- 修正結果レポートを出力して完了とする

### Phase 4: 検証
1. `terraform fmt -check` でフォーマット確認
2. `terraform validate` で構文検証
3. 必要に応じて `tflint` を実行

## Quality Criteria (レビュー観点)

- **命名規則**: snake_case、適切なプレフィックス
- **モジュール構造**: 標準的なファイル構成
- **共通パターン**: common_labels, resource_prefix
- **セキュリティ**: 秘密情報のハードコードなし、最小権限
- **ドキュメント**: 変数・出力の説明

## 終了時レポート

ループ上限（5回）に達した場合、以下の形式でレポートを出力:

```
## 実装結果レポート

### 実施内容
- 作成/修正したファイル一覧
- 主な変更内容

### レビュー履歴
- ループ回数: X/5
- 各ループでの指摘と対応

### 未解決の指摘事項
- 残っている指摘とその理由
- 推奨される対応方法

### 次のステップ
- 手動で確認が必要な項目
- 追加の検討事項
```

## Reference

- `.claude/rules/04-module-conventions.md` - モジュール規約
- `.claude/rules/05-security-testing.md` - セキュリティ基準
- `.claude/skills/terraform-review/SKILL.md` - レビュー基準
