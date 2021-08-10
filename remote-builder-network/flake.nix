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
      networkName = "builder";

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
    in
    eachDefaultEnvironment
      ({ pkgs, system }: {

        devShell = import ./shell.nix { inherit pkgs networkName; };

        packages = nixops-plugged.outputs.packages."${system}";

        overlay = final: prev:
          self.packages."${system}" // {
            nix = final.nixFlakes;
            nixops = final.nixops-plugged;
          };

        nixopsModules = {
          nixopsNetwork = ./nixops-modules/nixops-network;

          builderNetwork = ./nixops-modules/builder-network;

          network = {...}: {
            imports = with self.nixopsModules."${system}"; [
              nixopsNetwork
              builderNetwork
            ];
            builderNetwork = {
              name = networkName;
              aws.region = "us-east-1";
              aws.zone = "us-east-1b";
              nixosConfiguration = self.nixosConfigurations.builder;
              binaryCache.url = "s3://builder?region=us-east-1";
              binaryCache.publicKey = "builder:/0000000000000000000000000000000000000000000";
            };
            inherit nixpkgs;
          };
        };
      })
    // {
      nixosConfigurations.builder = ./nixos-configurations/builder;

      nixopsConfigurations.default =
        let
          networkConfig = (lib.evalModules {
            modules = with self.nixopsModules."x86_64-linux"; [
              nixopsNetwork
              network
            ];
          }).config;
        in
          { inherit (networkConfig) nixpkgs network resources; } // networkConfig.deployments;
    };
}

