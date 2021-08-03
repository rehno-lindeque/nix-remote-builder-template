{
  description = "Remote builder network on AWS EC2";

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
              overlays = [
                  (self: super: {
                    nixops = nixops.defaultPackage.${system};
                  })
                  (self: super: {
                    nixops = (import "${nixops-plugged}/nixops-pluggable.nix" super).nixops.withPlugins (plugins: [
                      plugins.nixops-aws
                    ]);
                  })
                ]
                ++ import ./overlays.nix;
              config.allowUnfree = true;
            };
          }
        );
    in
    eachDefaultEnvironment
      ({ pkgs, system }: {
        devShell = import ./shell.nix { inherit pkgs networkName; };
      })
    // {
      nixopsConfigurations.default = import ./nixops-configurations {} // {
        inherit nixpkgs networkName;
      };
    };
}

