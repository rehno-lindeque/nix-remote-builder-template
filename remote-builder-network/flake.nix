{
  description = "Remote builder and supporting infrastructure on AWS EC2";

  inputs = {
    # nixops.url = "github:nixos/nixops/2e67d89d126af9d2bf702da13efe73fbd471a5ec";
    # nixops.url = "github:nixos/nixops";
    # nixops.url = "github:rehno-lindeque/nixops?ref=wip";
    nixops-src.url = "path:/home/me/projects/development/nixops";
    nixops-src.flake = false;
    # nixops-plugged.url = "github:lukebfox/nixops-plugged";
    # nixops-plugged.inputs.nixpkgs.follows = "nixops/nixpkgs";
    # nixops-plugged.inputs.flake-utils.follows = "nixops/utils";
    # nixops-aws.url = "github:rehno-lindeque/nixops-aws?ref=spot-fleet";
    nixops-aws-src.url = "path:/home/me/projects/development/nixops-aws";
    nixops-aws-src.flake = false;
    # nixos-modules-contrib-src.url = "github:nix-community/nixos-modules-contrib/81a1c2ef424dcf596a97b2e46a58ca73a1dd1ff8";
    # nixos-modules-contrib-src.flake = false;
    # nixpkgs.follows = "nixops/nixpkgs";
    # utils.follows = "nixops/utils";
    nixpkgs.url = "github:nixos/nixpkgs";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, nixops-src, nixops-aws-src, utils, ... }:
    let
      inherit (nixpkgs) lib;

      networkName = "ml-builder";
      # networkName = "builder";

      eachDefaultEnvironment = f: utils.lib.eachDefaultSystem
        (
          system:
          f {
            inherit system;
            pkgs = nixpkgs.legacyPackages."${system}".extend self.overlay;
          }
        );

    in
    eachDefaultEnvironment ({ pkgs, system }: {

      devShell = import ./shell.nix {
        inherit networkName;
        pkgs = pkgs // self.packages."${system}";
      };

      packages = { inherit (pkgs) networkOps; };

      nixosModules = {
        builderNode = ./nixos-modules/builder-node;
      };
    }) // {

      lib.nixopsNetwork = { nixpkgs, modules, specialArgs }:
        let
          baseModule = {
            options = with lib.types; {
              network = lib.mkOption { type = attrsOf anything; };
              resources = lib.mkOption { type = attrsOf unspecified; };
              deployments = lib.mkOption { type = attrsOf unspecified; };
              nixpkgs = lib.mkOption { type = anything; };
            };
          };

          networkConfig =
            (lib.evalModules {
              modules = [ baseModule ] ++ modules;
              inherit specialArgs;
            }).config;
        in
          # lib.traceValSeqN 2 ({ inherit (networkConfig) network resources nixpkgs; } // networkConfig.deployments);
          ({ inherit (networkConfig) network resources nixpkgs; } // networkConfig.deployments);

      overlay = final: prev: {
        nix = final.nixFlakes;
        # nixops = nixops-plugged.packages."${final.system}".nixops-plugged;
        # nixops-aws = prev.callPackage nixops-aws {};
        # nixops = (lib.traceVal nixops.defaultPackage."x86_64-linux").withPlugins {};
        # nixops = (final.nixopsUnstable.override { overrides = self: super:
        #   {
        #   };
        # });
        # nixops = (lib.traceValSeqN 2 nixops).override {
        nixops = final.callPackage ./pkgs/nixops {
          overrides = final: prev: {
            nixops = prev.nixops.overridePythonAttrs (_: { src = nixops-src; });
            nixops-aws = prev.nixops-aws.overridePythonAttrs (_: { src = nixops-aws-src; });
          };
        };
        networkOps = final.callPackage ./. { inherit networkName; };
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

