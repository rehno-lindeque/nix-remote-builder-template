{
  description = "Remote builder and supporting infrastructure on AWS EC2";

  inputs = {
    nixops.url = "github:nixos/nixops/2e67d89d126af9d2bf702da13efe73fbd471a5ec";
    nixops-plugged.url = "github:lukebfox/nixops-plugged";
    nixops-plugged.inputs.nixpkgs.follows = "nixops/nixpkgs";
    nixops-plugged.inputs.flake-utils.follows = "nixops/utils";
    nixpkgs.follows = "nixops/nixpkgs";
    utils.follows = "nixops/utils";
  };

  outputs = { self, nixpkgs, nixops, nixops-plugged, utils, ... }:
    let
      inherit (nixpkgs) lib;

      eachDefaultEnvironment = f: utils.lib.eachDefaultSystem
        (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages."${system}".extend self.overlay;
          }
        );

      nixopsNetwork = { nixpkgs, modules, specialArgs }:
        let
          baseModule = {
            options = with lib.types; {
              network = lib.mkOption { type = attrsOf anything; };
              resources = lib.mkOption { type = attrsOf anything; };
              deployments = lib.mkOption { type = attrsOf anything; };
              nixpkgs = lib.mkOption { type = anything; };
            };
          };

          networkConfig =
            (lib.evalModules {
              modules = [ baseModule ] ++ modules;
              inherit specialArgs;
            }).config;
        in
          { inherit (networkConfig) network resources nixpkgs; } // networkConfig.deployments;

      networkName = "builder";
    in
    eachDefaultEnvironment
      ({ pkgs, system }: {

        devShell = import ./shell.nix { inherit pkgs networkName; inherit (self.packages."${system}") networkOps; };

        packages = nixops-plugged.outputs.packages."${system}" // { networkOps = pkgs.callPackage ./. { inherit networkName; }; };

        nixosModules = {
          builderNode = ./nixos-modules/builder-node;
        };
      })
    // {
      overlay = final: prev: self.packages."${system}" //
        nix = final.nixFlakes;
        nixops = nixops-plugged.packages."${final.system}".nixops-plugged;
      };

      nixopsModules = {
        builderNetwork = ./nixops-modules/builder-network;
      };

      nixopsConfigurations.default = self.lib.nixopsNetwork {
        modules = [ ./nixops-configurations ];
        specialArgs.flake = self;
        inherit nixpkgs;
      };

    };
}

