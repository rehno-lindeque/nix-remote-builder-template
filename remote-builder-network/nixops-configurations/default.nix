{ networkName ? "builder"
, networkDescription ? "${networkName} network"
, region ? "us-east-1"
, zone ? "us-east-1b"
, ...
}:

let
  common = {
    inherit networkName region zone;
  };

  instances = import ./ec2/instances.nix common;
  keys = {
    # binary-cache-key = {
    #   keyCommand = [ "vault" "kv" "get" "-field" "key" "secret/builder/nix-binary-cache" ];
    # };
  };
in
{
  network.description = networkDescription;
  network.enableRollback = true;

  # Currently only legacy state storage is supported
  network.storage.legacy = { };

  # network.storage.s3 = {
  #   profile = "";
  #   region = "us-east-1";
  #   key = "";
  #   kms_keyid = "";
  # };

  resources =
    import ./ec2/resources.nix common
    // import ./iam/resources.nix common
    // import ./s3/resources.nix common
    // import ./vpc/resources.nix common;

  defaults = instances.defaults;

  builder-1 = { resources, lib, ... }@args: {
    deployment = instances.builder args // { inherit keys; };
    imports = [
      ../nixos-configurations/builder
    ];
  };
}

