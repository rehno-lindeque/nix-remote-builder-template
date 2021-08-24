{ flake
, lib
, ...
}:

{
  imports = [
    flake.nixopsModules.builderNetwork
  ];

  builderNetwork = {
    aws.region = "us-east-1";
    aws.zone = "us-east-1b";
    binaryCache.url = "s3://builder?region=us-east-1";
    binaryCache.publicKey = "builder:/0000000000000000000000000000000000000000000";
    builderConfigurations = {
      builder-1 = flake.nixosModules."x86_64-linux".builderNode;
    };
  };

  deployments.defaults = {
    nix.sshServe.keys = [
      # Add your own public key here
    ];
  };

  nixpkgs = flake.inputs.nixpkgs;
}
