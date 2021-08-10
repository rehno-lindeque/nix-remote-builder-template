{ config
, lib
, ...
}:

let
  # nixos-configuration = ../../nixos-configurations/builder;
  builderNetwork = config.builderNetwork;

  instances = import ./aws/instances.nix {
    networkName = builderNetwork.name;
    inherit (builderNetwork.aws) region zone;
  };

  keys = {
    binary-cache-key = {
      keyCommand = [ "vault" "kv" "get" "-field" "key" "secret/builder/nix-binary-cache" ];
    };
  };

  builderOptions =  {
    name = lib.mkOption {
      type = lib.types.str;
      default = "builder";
    };
    aws = {
      region = lib.mkOption {
        type = lib.types.str;
        default = "us-east-1";
      };
      zone = lib.mkOption {
        type = lib.types.str;
        default = "us-east-1b";
      };
    };
    binaryCache = {
      url = lib.mkOption {
        type = lib.types.str;
      };
      publicKey = lib.mkOption {
        type = lib.types.str;
      };
    };
    nixosConfiguration = lib.mkOption {
      type = lib.types.anything;
    };
  };
in
{
  imports = [
    ./aws/resources
  ];

  options.builderNetwork = builderOptions;

  config = {
    network.description = lib.mkDefault "${builderNetwork.name} network";
    network.enableRollback = lib.mkDefault true;

    # Currently only legacy state storage is supported
    network.storage.legacy = { };

    # network.storage.s3 = {
    #   profile = "";
    #   region = "us-east-1";
    #   key = "";
    #   kms_keyid = "";
    # };

    deployments.builder-1 = { resources, lib, ... }@args: {
      imports = [
        builderNetwork.nixosConfiguration
      ];
      options.builderNetwork = {
        inherit (builderOptions) name binaryCache;
      };
      config = {
        deployment = instances.builder args // { inherit keys; };
        builderNetwork = {
          inherit (config.builderNetwork) name binaryCache;
        };
      };
    };
  };
}

