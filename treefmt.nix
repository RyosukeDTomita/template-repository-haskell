{ pkgs, unstablePkgs, ... }:
{
  projectRootFile = "flake.nix";

  # nix ファイルの整形。nixfmt-tree と同じ RFC 166 スタイルに揃える。
  programs.nixfmt.enable = true;
  programs.nixfmt.package = pkgs.nixfmt-rfc-style;

  # mdformat 本体は thematic break を変換するため、`---` のまま出力する
  # mdformat-simple-breaks プラグインを使う。programs.mdformat は package
  # 上書きを尊重しないため settings.formatter で直接指定する。
  # .claude/ 配下の SKILL.md は YAML frontmatter を持ち、mdformat が壊すので除外する。
  settings.formatter.mdformat = {
    command = "${pkgs.mdformat.withPlugins (ps: with ps; [ ps.mdformat-simple-breaks ])}/bin/mdformat";
    includes = [ "*.md" ];
    excludes = [ ".claude/**" ];
  };

  # flake.nix の hpkgs と同じ GHC のバージョンに合わせる。
  programs.ormolu.enable = true;
  programs.ormolu.package = pkgs.haskell.packages.ghc9122.ormolu;

  # treefmt controls mode/idempotence itself; pass only parser options.
  settings.formatter.ormolu.options = [
    "--ghc-opt"
    "-XImportQualifiedPost"
  ];

  # GitHub Actions の uses をコミットハッシュに固定する。
  # --update はバージョンを勝手に上げるため無効にし、未固定の uses の固定だけ行う。
  programs.pinact.enable = true;
  programs.pinact.package = unstablePkgs.pinact;
  programs.pinact.update = false;

  # GitHub Actions のセキュリティ lint(整形はしない)。
  # ghalint run はファイル引数を取らず .github/workflows を自分で走査するため、
  # treefmt が渡す引数は捨てる。
  # pinact が固定した後の内容を検査するよう priority で後に回す。
  settings.formatter.ghalint = {
    priority = 1;
    command = "${pkgs.writeShellScript "ghalint-run" ''exec ${unstablePkgs.ghalint}/bin/ghalint run''}";
    includes = [
      ".github/workflows/*.yml"
      ".github/workflows/*.yaml"
    ];
  };
}
