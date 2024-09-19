{ pkgs, inputs, ... }:

{
  packages = [
    pkgs.git
    pkgs.nixfmt-rfc-style
    inputs.dagger.packages.${pkgs.stdenv.system}.dagger
  ];

  languages = {
    nix.enable = true;
    go.enable = true;
    go.package = pkgs.go_1_23;
  };

  pre-commit.hooks = {
    treefmt = {
      enable = true;
    };
  };

  languages.python.enable = true;

  # https://github.com/cachix/devenv/pull/1317
  # treefmt = {
  #   programs.nixfmt.enable = true;
  #   programs.nixfmt.package = pkgs.nixfmt-rfc-style;
  # };
}
