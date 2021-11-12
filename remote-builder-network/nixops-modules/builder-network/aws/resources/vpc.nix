{ config
, lib
, ...
}:

let
  builderNetwork = config.builderNetwork;
  zoneLetter = lib.lists.elemAt [ "a" "b" "c" "d" "e" "f" ];
in
{
  resources.vpc."${builderNetwork.name}-vpc" = {
    inherit (builderNetwork.aws) region;
    instanceTenancy = "default";
    enableDnsSupport = true;
    enableDnsHostnames = true;
    cidrBlock = "10.0.0.0/16";
  };

  resources.vpcSubnets =
    let
      zoneCidrs = [ "10.0.0.0/19" "10.0.32.0/19" "10.0.64.0/19" "10.0.96.0/19" "10.0.128.0/19" "10.0.160.0/19" ];
      mkSubnet = n:
        lib.nameValuePair
          "${builderNetwork.name}-subnet-${zoneLetter n}"
          ({ resources, ... }: {
            inherit (builderNetwork.aws) region;
            zone = "${builderNetwork.aws.region}${zoneLetter n}";
            vpcId = resources.vpc."${builderNetwork.name}-vpc";
            cidrBlock = lib.lists.elemAt zoneCidrs n;
            mapPublicIpOnLaunch = true;
          });
    in
      # Create a subnet in each availability zone
      lib.listToAttrs (map mkSubnet (lib.range 0 5));

  resources.vpcRouteTables."${builderNetwork.name}-route-table" = { resources, ... }: {
    inherit (builderNetwork.aws) region;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
  };

  resources.vpcRouteTableAssociations =
    let
      mkRouteTableAssociation = n:
        lib.nameValuePair
          "${builderNetwork.name}-association-${zoneLetter n}"
          ({ resources, ... }: {
            inherit (builderNetwork.aws) region;
            subnetId = resources.vpcSubnets."${builderNetwork.name}-subnet-${zoneLetter n}";
            routeTableId = resources.vpcRouteTables."${builderNetwork.name}-route-table";
          });
    in
      # Create an association to a subnet in each availability zone
      lib.listToAttrs (map mkRouteTableAssociation (lib.range 0 5));

  resources.vpcRoutes."${builderNetwork.name}-igw-route" = { resources, ... }: {
    inherit (builderNetwork.aws) region;
    routeTableId = resources.vpcRouteTables."${builderNetwork.name}-route-table";
    destinationCidrBlock = "0.0.0.0/0";
    gatewayId = resources.vpcInternetGateways."${builderNetwork.name}-igw";
  };

  resources.vpcInternetGateways."${builderNetwork.name}-igw" = { resources, ... }: {
    inherit (builderNetwork.aws) region;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
  };
}
