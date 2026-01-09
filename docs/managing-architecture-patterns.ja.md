# アーキテクチャパターンの管理

このガイドでは、リポジトリ内のアーキテクチャパターンの追加、削除、変更方法を説明します。

## 一元化されたパターン設定

すべてのアーキテクチャパターンは、**単一の場所**で定義されています:

```
.github/workflows/_patterns-config.yml
```

この再利用可能なワークフローが、すべてのCI/CDワークフローにとってのシングルソースオブトゥルース（唯一の真実の源）として機能します。

## パターンの定義

### 全パターン
リポジトリ内のアーキテクチャパターンの完全なリスト:

```yaml
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch"]'
```

このリストは以下で使用されます:
- `terraform-ci.yml` - すべてのパターンをテスト
- `terraform-plan-pr.yml` - すべてのパターンをプラン
- `terraform-apply.yml` - すべてのパターンをデプロイ（自動適用が有効な場合）

### 本番環境パターン
本番環境へのデプロイが承認されているパターンのサブセット:

```yaml
PROD_PATTERNS='["event-driven"]'
```

このリストは以下で使用されます:
- `terraform-apply-with-approval.yml` - 承認されたパターンのみを本番環境にデプロイ

## 新しいアーキテクチャパターンの追加

リポジトリに新しいアーキテクチャパターンを追加するには:

### 1. アーキテクチャディレクトリ構造の作成

```bash
mkdir -p architectures/new-pattern/gcp/{modules,environments/{dev,prod}}
```

### 2. Terraformコードの実装

`.claude/rules/04-module-conventions.md`に記載されているモジュール規約に従ってください:
- `modules/`にモジュールを作成
- `environments/{dev,prod}/`に環境設定を作成
- 命名規則に従う（snake_case）
- 適切なドキュメントを追加

### 3. パターン設定の更新

`.github/workflows/_patterns-config.yml`を編集:

```yaml
# 新しいパターンをALL_PATTERNSに追加
ALL_PATTERNS='["event-driven", "microservices-gke", "workflow-batch", "new-pattern"]'

# 本番環境の準備ができている場合は、PROD_PATTERNSにも追加（オプション）
PROD_PATTERNS='["event-driven", "new-pattern"]'
```

### 4. ワークフローの手動実行オプションの更新（オプション）

手動ワークフロートリガーでパターンを使用できるようにする場合、以下を編集:

`.github/workflows/terraform-apply.yml`:
```yaml
workflow_dispatch:
  inputs:
    architecture:
      options:
        - event-driven
        - microservices-gke
        - workflow-batch
        - new-pattern  # ここに追加
```

### 5. パターンのテスト

CI/CDワークフローは自動的に以下を実行します:
- フォーマットチェックと検証
- TFLintの実行
- セキュリティスキャン
- PR作成時のTerraform planの生成

## アーキテクチャパターンの削除

既存のパターンを削除するには:

### 1. パターン設定から削除

`.github/workflows/_patterns-config.yml`を編集:

```yaml
# 両方のリストからパターンを削除
ALL_PATTERNS='["event-driven", "microservices-gke"]'
PROD_PATTERNS='["event-driven"]'
```

### 2. 手動ワークフローから削除（存在する場合）

`.github/workflows/terraform-apply.yml`を編集してoptionsから削除します。

### 3. ディレクトリをアーカイブまたは削除

```bash
# オプション1: 参照用に保持するが、git追跡から削除
git rm -r --cached architectures/old-pattern/

# オプション2: 完全に削除
git rm -r architectures/old-pattern/
```

### 4. クラウドリソースの破棄（デプロイ済みの場合）

パターンを削除する前に、デプロイされたインフラストラクチャを破棄してください:

```bash
cd architectures/old-pattern/gcp/environments/dev
terraform destroy

cd ../prod
terraform destroy
```

## 本番環境デプロイの有効化/無効化

どのパターンを本番環境にデプロイできるかを制御するには:

### 本番環境デプロイの有効化

`_patterns-config.yml`の`PROD_PATTERNS`にパターンを追加:

```yaml
PROD_PATTERNS='["event-driven", "microservices-gke"]'
```

### 本番環境デプロイの無効化

`PROD_PATTERNS`からパターンを削除:

```yaml
# event-drivenのみ本番環境にデプロイ可能
PROD_PATTERNS='["event-driven"]'
```

これは以下に影響します:
- `terraform-apply-with-approval.yml` - リストにないパターンはスキップされます
- 本番環境の保護ルールは引き続き適用されます

## 一元管理のメリット

### 変更前（分散定義）
- パターンが4つ以上のワークフローファイルで定義されている
- ワークフロー間で不整合が発生するリスク
- メンテナンスがエラーを起こしやすい（1つのファイルを見落としやすい）

### 変更後（一元管理）
- `_patterns-config.yml`に唯一の真実の源
- すべてのワークフローが自動的に同期
- パターンの追加/削除が簡単（1つのファイルを編集するだけ）
- すべてのパターンと本番承認済みパターンの明確な分離

## ワークフロー出力

`_patterns-config.yml`ワークフローは3つの出力を提供します:

| 出力 | タイプ | 説明 | 例 |
|------|--------|------|-----|
| `all_patterns` | JSON配列 | マトリックス戦略用のすべてのパターン | `["event-driven", "microservices-gke", "workflow-batch"]` |
| `all_patterns_list` | 文字列 | 表示用のカンマ区切り | `event-driven,microservices-gke,workflow-batch` |
| `prod_patterns` | JSON配列 | 本番承認済みパターン | `["event-driven"]` |

## 例: "Serverless API"パターンの追加

新しいパターンを追加する完全な例:

```bash
# 1. 構造を作成
mkdir -p architectures/serverless-api/gcp/{modules,environments/{dev,prod}}

# 2. Terraformコードを実装（モジュールと環境）
# ... (Terraformファイルを作成)

# 3. _patterns-config.ymlを更新
# ファイルを編集して"serverless-api"をALL_PATTERNSに追加

# 4. 手動ワークフローオプションを更新（オプション）
# terraform-apply.ymlを編集してworkflow_dispatchオプションに追加

# 5. コミットしてプッシュ
git add architectures/serverless-api/
git add .github/workflows/_patterns-config.yml
git commit -m "feat: serverless-apiアーキテクチャパターンを追加"
git push
```

次のPRでCI/CDパイプラインが自動的に新しいパターンをテストします。

## トラブルシューティング

### パターンがCIで実行されない

以下を確認してください:
1. `_patterns-config.yml`の`ALL_PATTERNS`にパターンが記載されている
2. パターンディレクトリが`architectures/<pattern>/gcp/`に存在する
3. ワークフローの構文が有効（GitHub Actionsがエラーを表示します）

### 手動デプロイでパターンが利用できない

以下を確認してください:
1. `terraform-apply.yml`の`workflow_dispatch.inputs.architecture.options`にパターンがある
2. パターンが`ALL_PATTERNS`（dev/prod用）または`PROD_PATTERNS`（本番のみ）にある

### 本番環境デプロイが動作しない

以下を確認してください:
1. `_patterns-config.yml`の`PROD_PATTERNS`にパターンが記載されている
2. GitHubで本番環境保護ルールが設定されている
3. 本番環境に必要な承認者が設定されている
