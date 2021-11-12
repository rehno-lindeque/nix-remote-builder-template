{ config, ... }:

{
  imports = [
    ./ec2.nix
    ./iam.nix
    ./instances.nix
    ./s3.nix
    ./spot-fleet.nix
    ./vpc.nix
  ];
}

