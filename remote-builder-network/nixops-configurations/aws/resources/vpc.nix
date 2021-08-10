{ config
, ...
}:

let
  builderNetwork = config.builderNetwork;
in
{
  resources.vpc."${builderNetwork.name}-vpc" = {
    inherit (builderNetwork) region;
    instanceTenancy = "default";
    enableDnsSupport = true;
    enableDnsHostnames = true;
    cidrBlock = "10.0.0.0/16";
  };

  resources.vpcSubnets."${builderNetwork.name}-subnet" = { resources, ... }: {
    inherit (builderNetwork) region zone;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
    cidrBlock = "10.0.0.0/16";
    mapPublicIpOnLaunch = true;
  };

  resources.vpcRouteTables."${builderNetwork.name}-route-table" = { resources, ... }: {
    inherit (builderNetwork) region;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
  };

  resources.vpcRouteTableAssociations."${builderNetwork.name}-association" = { resources, ... }: {
    inherit (builderNetwork) region;
    subnetId = resources.vpcSubnets."${builderNetwork.name}-subnet";
    routeTableId = resources.vpcRouteTables."${builderNetwork.name}-route-table";
  };

  resources.vpcRoutes."${builderNetwork.name}-igw-route" = { resources, ... }: {
    inherit (builderNetwork) region;
    routeTableId = resources.vpcRouteTables."${builderNetwork.name}-route-table";
    destinationCidrBlock = "0.0.0.0/0";
    gatewayId = resources.vpcInternetGateways."${builderNetwork.name}-igw";
  };

  resources.vpcInternetGateways."${builderNetwork.name}-igw" = { resources, ... }: {
    inherit (builderNetwork) region;
    vpcId = resources.vpc."${builderNetwork.name}-vpc";
  };
}
