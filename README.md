# template-repository-haskell <!--fix-me-->

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## ABOUT

Nix flake ベースの Haskell プロジェクトテンプレート。

---

## HOW TO USE

### Initial Set Up

```shell
nix develop
# direnv を使う場合
direnv allow
```

### run locally

```shell
cabal run myapp
```

```shell
# 引数を渡したい場合
cabal run myapp -- <ARG>
```

```shell
# デバッグなら runghc の方が気楽
runghc -isrc -iapp app/Main.hs Haskell
```

### test

```shell
runghc -isrc test/Spec.hs
```

### build

```shell
# nix store に動的リンクしたバイナリ(test-suite も実行される)
nix build
# 配布用の musl 静的バイナリ(初回はソースビルドになり時間がかかる)
nix build .#static
```

### formatter

treefmt(ormolu / nixfmt / mdformat)でまとめて整形する。
GitHub Actionsのworkflowも対象で、pinactが`uses`をコミットハッシュに固定し、ghalintがセキュリティポリシーを検査する。
pinactはGitHub APIを使うため、ネットワークの無い`nix flake check`ではpinactを除外している。

```shell
nix fmt
# 整形漏れのチェック(CI でも実行)
nix flake check
```

### ライブラリの追加

`myapp.cabal` の `build-depends` に足して `nix develop` に入り直す(direnv なら自動)。
devShell は `hpkgs.shellFor` で `.cabal` から依存を読むので、`flake.nix` を触る必要はない。
パッケージは nixpkgs(`nixos-25.05`)に入っている版が使われ、Hackage からは取得しない。
`cabal.project` の `active-repositories: :none` で cabal からも Hackage を参照させない。
シェルに入り直す前に `cabal build` すると `unknown package` で止まる(ダウンロードはしない)。
import を変えたら `.ghci` も同期する(`CLAUDE.md` 参照)。

### GHC のバージョンを上げる

`flake.nix` の `hpkgs` / `packages.static` と `treefmt.nix` の ormolu の `ghc9122` を揃えて変更する。
