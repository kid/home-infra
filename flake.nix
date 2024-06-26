{
  description = "Description for the project";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devenv.url = "github:cachix/devenv";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
        inputs.devenv.flakeModule
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
          self',
          inputs',
          pkgs,
          system,
          ...
        }:
        {
          # Per-system attributes can be defined here. The self' and inputs'
          # module parameters provide easy access to attributes of the same
          # system.

          _module.args.pkgs = import inputs.nixpkgs {
            inherit system;
            config.allowUnfree = true;
          };

          devenv.shells.default = {
            # languages.ansible.enable = true;
            packages = with pkgs; [
              config.treefmt.build.wrapper
              azure-cli
              (ansible.overrideAttrs (oldAttrs: {
                propagatedBuildInputs = oldAttrs.propagatedBuildInputs ++ [ pkgs.python311Packages.librouteros ];
              }))
              ansible-lint
              ansible-language-server
              sops
              terragrunt
              terraform
              terraform-ls
              talosctl
              timoni
              cue
              fluxcd
              cilium-cli
              hubble
              kubernetes-helm
            ];

            scripts = {
              ansible-deploy.exec = ''
                cd "$DEVENV_ROOT/ansible"
                ansible-playbook -i inventory/hosts.ini site.yml --diff "$@"
              '';
            };
          };

          treefmt = {
            projectRootFile = "flake.nix";
            # build.check = true;
            flakeFormatter = true;
            programs.nixfmt.enable = true;
            programs.nixfmt.package = pkgs.nixfmt-rfc-style;
            programs.terraform.enable = true;
            programs.cue.enable = true;
          };
        };
    };
}
