{ pkgs, inputs, ... }:

{
  devcontainer.enable = true;

  packages =
    [
      inputs.dagger.packages.${pkgs.stdenv.system}.dagger
      inputs.talhelper.packages.${pkgs.stdenv.system}.talhelper
    ]
    ++ (with pkgs; [
      git
      nixfmt-rfc-style
      containerlab
      expect
      inetutils
      fluxcd
      kubernetes-helm
      kustomize
      kustomize-sops
      sops
      cilium-cli
      talosctl
      timoni
      go-task
      iptables
      qemu-utils
      kubectl
    ]);

  languages = {
    nix.enable = true;
    go = {
      enable = true;
      package = pkgs.go_1_23;
    };
    terraform = {
      enable = true;
      package = pkgs.opentofu;
    };
  };

  pre-commit.hooks = {
    treefmt = {
      enable = true;
    };
  };

  # https://github.com/cachix/devenv/pull/1317
  # treefmt = {
  #   programs.nixfmt.enable = true;
  #   programs.nixfmt.package = pkgs.nixfmt-rfc-style;
  # };
}
