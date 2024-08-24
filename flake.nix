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

    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.nix-topology.flakeModule
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
                azure-cli
                age
                sops
                terragrunt
                terraform-ls
                talosctl
                timoni
                cue
                fluxcd
                cilium-cli
                hubble
                kubernetes-helm
                kubectl-cnpg
                kubeconform
                kustomize
                earthly
                opentofu
                pdns
                containerlab
                gopls
                terraform-backend-git
              ]);
          };

          treefmt = {
            projectRootFile = "flake.nix";
            # build.check = true;
            flakeFormatter = true;
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rfc-style;
            programs.terraform.enable = true;
            programs.hclfmt.enable = true;
            programs.cue.enable = true;
            programs.shfmt.enable = true;
            programs.gofmt.enable = true;
            programs.yamlfmt.enable = true;
          };

          topology.modules = [
            {
              networks.lan = {
                name = "lan";
                cidrv4 = "10.0.100.0/24";

              };
            }
          ];
        };
    };
}
