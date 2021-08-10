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

          nixosModules = {
            nixopsNetwork = {
              options = with lib.types; {
                network = lib.mkOption { type = attrsOf anything; };
                resources = lib.mkOption { type = attrsOf anything; };
                deployments = lib.mkOption { type = attrsOf anything; };
                nixpkgs = lib.mkOption { type = anything; };
              };
              config = {
                nixpkgs = lib.mkDefault nixpkgs;
              };
            };

            network = {...}: {
              imports = [ ./nixops-configurations ];
              builderNetwork = {
                name = networkName;
                region = "us-east-1";
                zone = "us-east-1b";
                binaryCachePublicKey = "builder:/0000000000000000000000000000000000000000000";
                nixosConfiguration = self.nixosConfigurations.builder;
              };
            };
          };
      })
    // {
      nixosConfigurations.builder = ./nixos-configurations/builder;

      nixopsConfigurations.default =
        let
          networkConfig = (lib.evalModules {
            modules = with self.nixosModules."x86_64-linux"; [
              nixopsNetwork
              network
            ];
          }).config;
        in
          { inherit (networkConfig) nixpkgs network resources; } // networkConfig.deployments;
    };
}

