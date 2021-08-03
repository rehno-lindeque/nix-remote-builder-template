{ networkName
, region
, zone
}:

{
  ec2KeyPairs."${networkName}-keypair" = { inherit region; };

  # The --kill-obsolete argument can be used to forcibly delete this resource
  # if necessary (nixops' diff engine can't keep track of direct changes)
  ec2SecurityGroups."${networkName}-sg" = { resources, lib, ... }: {
    inherit region;
    vpcId = resources.vpc."${networkName}-vpc";
    rules = builtins.attrValues {
      ssh = { toPort = 22; fromPort = 22; sourceIp = "0.0.0.0/0"; };
      http = { toPort = 80; fromPort = 80; sourceIp = "0.0.0.0/0"; };
      https = { toPort = 443; fromPort = 443; sourceIp = "0.0.0.0/0"; };
    };
  };
}

