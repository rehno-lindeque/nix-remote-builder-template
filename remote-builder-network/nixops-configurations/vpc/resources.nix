{ networkName
, region ? "us-east-1"
, zone
, ...
}:

{
  vpc."${networkName}-vpc" = {
    inherit region;
    instanceTenancy = "default";
    enableDnsSupport = true;
    enableDnsHostnames = true;
    cidrBlock = "10.0.0.0/16";
  };

  vpcSubnets."${networkName}-subnet" = { resources, ... }: {
    inherit region zone;
    vpcId = resources.vpc."${networkName}-vpc";
    cidrBlock = "10.0.0.0/16";
    mapPublicIpOnLaunch = true;
  };

  vpcRouteTables."${networkName}-route-table" = { resources, ... }: {
    inherit region;
    vpcId = resources.vpc."${networkName}-vpc";
  };

  vpcRouteTableAssociations."${networkName}-association" = { resources, ... }: {
    inherit region;
    subnetId = resources.vpcSubnets."${networkName}-subnet";
    routeTableId = resources.vpcRouteTables."${networkName}-route-table";
  };

  vpcRoutes."${networkName}-igw-route" = { resources, ... }: {
    inherit region;
    routeTableId = resources.vpcRouteTables."${networkName}-route-table";
    destinationCidrBlock = "0.0.0.0/0";
    gatewayId = resources.vpcInternetGateways."${networkName}-igw";
  };

  vpcInternetGateways."${networkName}-igw" = { resources, ... }: {
    inherit region;
    vpcId = resources.vpc."${networkName}-vpc";
  };
}
