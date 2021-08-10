{ config, ... }:

{
  imports = [
    ./ec2.nix
    ./iam.nix
    ./s3.nix
    ./vpc.nix
  ];
}

