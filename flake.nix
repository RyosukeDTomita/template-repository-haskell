{
  description = "Haskell project template (Nix flake)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    # GitHub Actions メンテ用ツール(ghalint 等)は新しい nixpkgs から取る。
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
        unstablePkgs = import nixpkgs-unstable { inherit system; };
        # GHC のバージョンはここで一元管理する(treefmt.nix の ormolu も合わせること)。
        hpkgs = pkgs.haskell.packages.ghc9122;
        # treefmt.nix から unstablePkgs(pinact / ghalint)を参照できるようにする。
        treefmtEval = treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];
          _module.args.unstablePkgs = unstablePkgs;
        };
        # nix flake check はサンドボックス内でネットワークが無く、GitHub API を叩く
        # pinact は必ず失敗するため、チェック用の評価では pinact だけ外す。
        treefmtCheckEval = treefmt-nix.lib.evalModule pkgs {
          imports = [ ./treefmt.nix ];
          _module.args.unstablePkgs = unstablePkgs;
          programs.pinact.enable = pkgs.lib.mkForce false;
        };
        # README/docs/flake 等を変えてもビルドのハッシュが変わらないようにする。
        projectSrc = pkgs.lib.fileset.toSource {
          root = ./.;
          fileset = pkgs.lib.fileset.unions [
            ./myapp.cabal
            ./src
            ./app
            ./test
          ];
        };
        # 依存は myapp.cabal の build-depends だけで管理する。
        # callCabal2nix が build-depends を hpkgs の同名パッケージに解決する。
        myapp = hpkgs.callCabal2nix "myapp" projectSrc { };
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        # `nix flake check` で treefmt の整形漏れを検出する。
        checks.formatting = treefmtCheckEval.config.build.check self;

        # `nix build` で実行バイナリを生成する(nix store に動的リンクする開発用)。

        # callCabal2nix はビルド時に test-suite も実行する。
        packages.default = myapp;

        # musl静的バイナリ
        packages.static = pkgs.haskell.lib.justStaticExecutables (
          pkgs.pkgsStatic.haskell.packages.ghc9122.callCabal2nix "myapp" projectSrc { }
        );

        # cabalはHackageではなく、nixからパッケージを取得する
        devShells.default = hpkgs.shellFor {
          packages = _: [ myapp ];
          nativeBuildInputs = [
            treefmtEval.config.build.wrapper
            pkgs.zsh
            hpkgs.haskell-language-server
            pkgs.cabal-install
            # GitHub Actions のメンテ用ツール(配布物には含まれない)。
            unstablePkgs.pinact
            unstablePkgs.ghalint
          ];
        };
      }
    );
}
