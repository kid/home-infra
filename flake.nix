{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";

    devshell.url = "github:numtide/devshell";
    devshell.inputs.nixpkgs.follows = "nixpkgs";

    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";

    dagger.url = "github:dagger/nix";
    dagger.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      perSystem =
        {
          config,
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devshells.default = {
            packages =
              [
                config.treefmt.build.wrapper
                inputs'.dagger.packages.dagger
              ]
              ++ (with pkgs; [
                age
                sops
                terraform-ls
                talosctl
                timoni
                fluxcd
                cilium-cli
                hubble
                kubernetes-helm
                kubectl-cnpg
                kubeconform
                kustomize
                earthly
                opentofu
                gopls
              ]);
          };

          treefmt = {
            projectRootFile = "flake.nix";
            flakeFormatter = true;
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rfc-style;
            programs.terraform.enable = true;
            programs.hclfmt.enable = true;
            programs.shfmt.enable = true;
            programs.gofmt.enable = true;
            programs.yamlfmt.enable = true;
          };
        };
    };
}
