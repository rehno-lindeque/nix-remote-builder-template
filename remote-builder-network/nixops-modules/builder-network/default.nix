{ flake
, config
, lib
, ...
}:

let
  builderNetwork = config.builderNetwork;

  builderNetworkOptions =  {
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

      managedS3Bucket = {
        enable = lib.mkEnableOption "Create and manage an s3 bucket resource";
        name = lib.mkOption {
          type = lib.types.str;
          default = "builder";
        };
      };
    };

    builderConfigurations = lib.mkOption {
      type = lib.types.attrsOf lib.types.anything; # One or more nixos configurations
      description = "NixOS deployment configuration of each builder node.";
    };
  };

  instances = import ./aws/instances.nix {
    networkName = builderNetwork.name;
    inherit (builderNetwork.aws) region zone;
  };

  mkDeployment = configuration: { resources, lib, ... }@args: {
      imports = [
        configuration
      ];
      options.builderNetwork = {
        inherit (builderNetworkOptions) name binaryCache;
      };
      config = {
        deployment = instances.builder args;
        builderNetwork = {
          inherit (config.builderNetwork) name binaryCache;
        };
      };
    };
in
{
  imports = [
    ./aws/resources
  ];

  options.builderNetwork = builderNetworkOptions;

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

    deployments = lib.mapAttrs (_: mkDeployment) builderNetwork.builderConfigurations;

  };
}

