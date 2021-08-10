{ config
, ...
}:

let
  builderNetwork = config.builderNetwork;
in
{
  resources.ec2KeyPairs."${builderNetwork.name}-keypair" = { inherit (builderNetwork.aws) region; };

  # The --kill-obsolete argument can be used to forcibly delete this resource
  # if necessary (nixops' diff engine can't keep track of direct changes)
  resources.ec2SecurityGroups."${builderNetwork.name}-sg" = { resources, lib, ... }: {
    inherit (builderNetwork.aws) region;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
    rules = builtins.attrValues {
      ssh = { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; };
      http = { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; };
      https = { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; };
    };
  };
}

