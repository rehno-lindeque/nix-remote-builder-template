{ flake
, ...
}:

{
  imports = [
    flake.nixopsModules.builderNetwork
  ];

  builderNetwork = {
    name = "builder";
    aws = {
      region = "us-east-1";
      zone = "us-east-1b";

      # For current spot instance pricing, see
      # https://aws.amazon.com/ec2/spot/pricing
      # https://aws.amazon.com/ec2/spot/instance-advisor/
      instanceType = "t2.micro";
      spotInstancePrice = 1;
    };
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
    deployment.keys = {
      binary-cache-key = {
        # Replace this placeholder. See option #1 and option #2
        text = lib.trace "TODO: replace binary-cache-key with a path or keyCommand" "";

        # Option #1: Add a key file to a secret sub-directory
        # path = ./secret/binary-cache-key

        # Option #2: Fetch the key via some external command like pass or vault
        # keyCommand = [ ... ];
      };
    };

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
