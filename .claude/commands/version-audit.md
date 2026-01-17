---
description: CI/CD、Terraform、その他のリソースのバージョン差分とパッチ適用状況を調査・分析・レポート
---

## Task

プロジェクト内の各リソースのバージョン情報を調査し、最新バージョンとの差分を分析してレポートを作成してください。

### 調査対象

1. **GitHub Actions**
   - `.github/workflows/*.yml` 内の `uses:` で指定されたアクション
   - 例: `actions/checkout@v4`, `hashicorp/setup-terraform@v3`

2. **Terraform**
   - `versions.tf` 内の `required_version`
   - プロバイダーのバージョン制約（`hashicorp/google` 等）

3. **TFLint**
   - `.tflint.hcl` 内のプラグインバージョン

4. **その他**
   - `package.json` があれば依存パッケージ
   - Dockerイメージのベースイメージ

### 調査方法

1. プロジェクト内のバージョン指定を検索
2. WebSearchで各ツールの最新バージョンを確認
3. 差分を分析

### レポート形式

```markdown
## バージョン監査レポート

### サマリー
- 最新: X件
- 更新推奨: X件
- セキュリティパッチあり: X件

### GitHub Actions
| アクション | 現行 | 最新 | ステータス |
|-----------|------|------|-----------|
| actions/checkout | v4 | v4 | ✅ 最新 |

### Terraform
| 項目 | 現行 | 最新 | ステータス |
|-----|------|------|-----------|
| Terraform | >= 1.13 | 1.x.x | ... |

### 推奨アクション
1. [優先度高] ...
2. [優先度中] ...
```
