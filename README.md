# ghpr.sh

GitHub の Pull Request 駆動のリリース作業を簡略化するためのツール。
リリース用の Pull Request を自動生成し、Release の記述や tag 付けを行うことができる。

このスクリプトは Pull Request を使っていてかつ Merge コミットを生成していることを前提に、 TravisCI や CircleCI などの CIaaS と連携して使うことを想定している。

## Motivation

例えば、 リリース準備中のブランチ `develop` と、リリース済みのブランチ `master` があるとする。
機能追加・改善・バグ修正などのあらゆる commit はまず `develop` にマージされ、然るべきタイミングで `master` にマージすることでリリースしたと見なす運用の場合、次のようなタスクが発生する。

- `develop` を `master` にマージするための Pull Request を作成する
- `master` にマージしたら tag 付けをする
- tag 付けをしたら GitHub の Release を作成する
- もしくは Changelog.md を更新する

これらのタスクが億劫なので、スクリプト化したものが `ghpr.sh` である。

### Why don't use `hub`

本ツールの機能のほとんどは [hub](https://github.com/github/hub) でも行うことができる。
しかし hub v2.5.0 時点では、既存の Pull Request の更新ができない ([Issue](https://github.com/github/hub/issues/1650)はある)

## Usage

```console
Usage:
  ghpr.sh [-h] [-t title] [-r remote] <org> <repo> <base> <head>

  arguments:
    org : Creation target GitHub organization name
    repo: Creation target GitHub repository name
    base: Pull request source branch
    head: Pull request target branch

  envionment:
    GHPRGEN_GITHUB_API_TOKEN: GitHub personal api token

  options:
    -t title : Pull reuqest title (default: "Merge <base> into <head>")
    -b body  : Pull reuqest body (default: listed merge pull requests)
    -u remote: Repository name of base branch to take merge commit
    -r remote: Repository name of head branch to take merge commit
    -p       : Only print pull request body
    -h       : Show usage

  example:
    GHPRGEN_GITHUB_API_TOKEN=xxxxxxxxxxx ./ghpr.sh yasuhiroki ghpr.sh master yasuhiroki:feature-branch
    GHPRGEN_GITHUB_API_TOKEN=xxxxxxxxxxx ./ghpr.sh -t 'New Pull Request' -u upstream -r origin yasuhiroki ghpr.sh master yasuhiroki:feature-branch
```

# LICENSE

[MIT](./LICENSE)
