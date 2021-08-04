{
  description = "Nix templates for deploying remote builder on AWS EC2";
  inputs = {
    remote-builder-network.url = "path:./remote-builder-network";
    nixpkgs.follows = "remote-builder-network/nixops/nixpkgs";
    utils.follows = "remote-builder-network/nixops/utils";

    # Avoid "follows a non-existent input" bug in nix 2.0
    # See https://github.com/NixOS/nix/issues/3602
    remote-builder-network.inputs.nixops-plugged.follows = "remote-builder-network/nixops-plugged";
  };

  outputs = { self, nixpkgs, utils, ... }:
    let
      eachDefaultEnvironment = f: utils.lib.eachDefaultSystem
        (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              overlays = import ./overlays.nix;
            };
          }
        );
    in
    eachDefaultEnvironment ({ pkgs, system }: {

      devShell = import ./shell.nix { inherit pkgs; };

    }) // {

      templates = {
        remote-builder-network = {
          path = ./remote-builder-network;
          description = "A template for deploying a remote builder and supporting infrastructure on AWS EC2";
        };
      };

      defaultTemplate = self.templates.remote-builder-network;

    };
}
