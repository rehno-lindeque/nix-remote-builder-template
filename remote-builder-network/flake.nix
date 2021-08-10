{
  description = "Remote builder and supporting infrastructure on AWS EC2";

  inputs = {
    nixops.url = "github:nixos/nixops";
    nixops-plugged.url = "github:lukebfox/nixops-plugged";
    nixops-plugged.inputs.nixpkgs.follows = "nixops/nixpkgs";
    nixops-plugged.inputs.flake-utils.follows = "nixops/utils";
    nixpkgs.follows = "nixops/nixpkgs";
    utils.follows = "nixops/utils";
  };

  outputs = { self, nixpkgs, nixops, nixops-plugged, utils, ... }:
    let
      eachDefaultEnvironment = f: utils.lib.eachDefaultSystem
        (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ self.overlay."${system}" ];
              config.allowUnfree = true;
            };
          }
        );

      inherit (nixpkgs) lib;

      networkName = "builder";
    in
    eachDefaultEnvironment
      ({ pkgs, system }: {

        devShell = import ./shell.nix { inherit pkgs; inherit networkName; };

        packages = nixops-plugged.outputs.packages."${system}";

        overlay = final: prev:
          self.packages."${system}" // {
            nix = final.nixFlakes;
            nixops = final.nixops-plugged;
          };

        nixopsModules = {
          nixopsNetwork = ./nixops-modules/nixops-network;

          builderNetwork = ./nixops-modules/builder-network;
        };
      })
    // {

      nixosConfigurations.builder = ./nixos-configurations/builder;

      nixopsConfigurations.default =
        let
          networkConfig = (lib.evalModules {
            modules = with self.nixopsModules."x86_64-linux"; [{
              imports = [
                nixopsNetwork
                builderNetwork
                ./nixops-configurations
              ];
              _module.args.flake = self;
              inherit nixpkgs;
              builderNetwork.name = networkName;
            }];
          }).config;
        in
          { inherit (networkConfig) nixpkgs network resources; } // networkConfig.deployments;
    };
}

