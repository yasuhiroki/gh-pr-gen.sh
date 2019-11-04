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
しかし hub v2.5.0 時点では、既存の Pull Request の更新ができない ([Issue](https://github.com/github/hub/issues/1650)はあり、 `hub pr show` でプルリクエストを表示する機能が v2.12.0 で実装された。

また、Pull Request の Number から Pull Request の Title を取得できない。
これらはいずれ解決されるだろうが今は解決されていない。しかし私が必要なのは今なので、本ツールを作っているし、使っている。

### Why use `ShellScript` instead of other language

特に深い理由はない。
強いて言えば、好きだから。

## Usage

本ツールの使い方は [.circleci/config.yml](.circleci/config.yml) が参考になるだろう。

