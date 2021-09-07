{ flake
, ...
}:

{
  imports = [
    flake.nixopsModules.builderNetwork
  ];

  builderNetwork = {
    aws.region = "us-east-1";
    aws.zone = "us-east-1b";
    binaryCache.url = "s3://nix-build?region=us-east-1";
    binaryCache.publicKey = "builder:/0000000000000000000000000000000000000000000";
    binaryCache.managedS3Bucket = {
      enable = false;
      name = "nix-build";
    };
    builderConfigurations = {
      builder-1 = flake.nixosModules."x86_64-linux".builderNode;
    };
  };

  deployments.defaults = { pkgs, lib, ... }: {
    nix.sshServe.keys = [
      # Add your own public key here
    ];

    environment.systemPackages =
      with pkgs;
      [
        # Add additional system packages
      ];
  };

  nixpkgs = flake.inputs.nixpkgs;
}
