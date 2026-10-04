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
runghc -isrc -iapp app/Main.hs Haskell
```

```shell
cabal run myapp
```

```shell
# 引数を渡したい場合
cabal run myapp -- <ARG>
```

### test

```shell
runghc -isrc test/Spec.hs
```

### build

```shell
# nix store に動的リンクしたバイナリ
nix build
# musl 静的バイナリは初回はソースビルドになり遅いが、Nixユーザ以外に配れるバイナリを作れる。
nix build .#static
```

### formatter

- treefmt
  - ormolu
  - nixfmt
  - mdformat
  - ghalint
  - pinact


> [!NOTE]
> pinactはGitHub APIを使うため、ネットワークの無い`nix flake check`ではpinactを除外している。

```shell
nix fmt
# 整形漏れのチェック(CI でも実行)
nix flake check
```

### ライブラリの追加

- `myapp.cabal` の `build-depends` に足す。
  - `direnv`不使用の場合には再度`nix develop`する
  - `flake.nix`のdevShellは`hpkgs.shellFor`で`.cabal` から依存を読む
- パッケージはnixpkgs経由で取得し、Hackageからは取得しない。
  - `cabal.project`にもHackageを参照させないように設定済み
- .ghciでデフォルトでimportするライブラリは`/sync-ghci`SKILLSで行う。

### GHC のバージョンを上げる

`flake.nix` の `hpkgs` / `packages.static` と `treefmt.nix` の ormolu の `ghc9122` を揃えて変更する。
