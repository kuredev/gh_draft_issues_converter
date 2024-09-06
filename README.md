# 概要
GitHubのProjectsのDraftIssueをIssueに一括で変換するツール。

# インストール

```sh
% gem install gh_draft_issues_conerter
```

# 使い方

事前に用意するもの

- Projectsの番号 ( `-p` で指定 )
- リポジトリ名(owner/repositoy)（ `-r` で指定）
- GitHub のPersonal Token（ `GITHUB_KEY` に登録しておくこと）

## 例

```sh
% gh_draft_issues_conerter -p 1 -r kuredev/gh-draft-issues-converter   
```

# 制約
- カスタムフィールドでは単一選択の物のみ移行されます
- 標準のフィールドは、assignのみ移行されます

