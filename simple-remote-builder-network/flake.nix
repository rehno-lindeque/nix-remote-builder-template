{
  description = "Remote builder and supporting infrastructure on AWS EC2";

  inputs = {
    # Included for easy diff
    template.url = "github:rehno-lindeque/nix-remote-builder-template?dir=simple-remote-builder-network";
    template.flake = false;

    # Remote builder
    remote-builder-network.url = "path:../remote-builder-network";
    # remote-builder-network.url = "github:rehno-lindeque/nix-remote-builder-template?dir=remote-builder-network";

    # Avoid "follows a non-existent input" bug in nix 2.0
    # See https://github.com/NixOS/nix/issues/3602
    nixops.url = "github:nixos/nixops/2e67d89d126af9d2bf702da13efe73fbd471a5ec";
    nixops-plugged.url = "github:lukebfox/nixops-plugged";
    nixops-plugged.inputs.nixpkgs.follows = "nixops/nixpkgs";
    nixops-plugged.inputs.flake-utils.follows = "nixops/utils";
    nixpkgs.follows = "nixops/nixpkgs";
    utils.follows = "nixops/utils";
  };

  outputs = { self, nixpkgs, utils, remote-builder-network, ... }:
    let
      inherit (nixpkgs) lib;

      networkName = "builder";

      eachDefaultEnvironment = f: utils.lib.eachDefaultSystem
        (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages."${system}".extend remote-builder-network.overlay;
          }
        );

    in
    eachDefaultEnvironment ({ pkgs, system }: {

      devShell = import ./shell.nix {
        inherit networkName;
        pkgs = pkgs // remote-builder-network.packages."${system}";
      };

    }) // {

      nixosModules = remote-builder-network.nixosModules;

      nixopsModules = remote-builder-network.nixopsModules;

      nixopsConfigurations.default = remote-builder-network.lib.nixopsNetwork {
        modules = [ ./nixops-configurations ];
        specialArgs.flake = self;
        inherit nixpkgs;
      };

    };
}

