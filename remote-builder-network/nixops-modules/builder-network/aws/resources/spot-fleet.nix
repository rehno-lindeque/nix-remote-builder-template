{ config
, references
, ...
}:
let
  builderNetwork = config.builderNetwork;
in
{
  resources.ec2LaunchTemplates."${builderNetwork.name}-template" = { resources, lib, ... }: {
    inherit (builderNetwork.aws) region;
    # templateName = "${builderNetwork.name}-template";
    name = "${builderNetwork.name}-template";
    ami = builderNetwork.aws.ami;

    # inherit instanceType region spotInstancePrice zone;
    associatePublicIpAddress = true;
    # subnetId = resources.vpcSubnets."${builderNetwork.name}-subnet";
    keyPair = resources.ec2KeyPairs."${builderNetwork.name}-keypair".name;

    # TODO: fix setting security group without subnet
    # securityGroupIds = [ resources.ec2SecurityGroups."${builderNetwork.name}-sg".name ];

    ebsInitialRootDiskSize = 30;
    instanceProfile = resources.iamRoles."${builderNetwork.name}-role".name;
    instanceType = ""; # TODO: currently necessary to prevent nix from defaulting to m1.small
    ebsOptimized = false;
  };
  resources.awsSpotFleets."${builderNetwork.name}-fleet" = { resources, lib, ... }:
    let
      availableSubnets = lib.attrValues resources.vpcSubnets;
      availableInstanceOfferings = (lib.importJSON ./instance-type-offerings.json).InstanceTypeOfferings;
      collectInstanceTypes =
        lib.groupBy'
          (result: offering: result ++ [ offering.InstanceType ])
          [ ]
          (offering: offering.Location);
      availableInstanceTypesPerZone =
        lib.mapAttrs
          (zone: lib.intersectLists builderNetwork.aws.instanceTypes)
          (collectInstanceTypes availableInstanceOfferings);
      overridesBySubnet = subnet:
        builtins.map
          (instanceType: { inherit instanceType; weightedCapacity = 1.; subnetId = subnet; })
          availableInstanceTypesPerZone.${subnet.zone};
    in
    {
      inherit (builderNetwork.aws) region;
      # allocationStrategy = "lowestPrice";
      allocationStrategy = "capacityOptimized";
      # iamFleetRole = resources.iamRoles."${builderNetwork.name}-fleet-role".name;
      iamFleetRole = resources.iamRoles."${builderNetwork.name}-fleet-role";
      targetCapacity = 1;
      type = "request";
      # type = "maintain";
      launchTemplateConfigs = [
        {
          launchTemplateSpecification = {
            launchTemplateId = resources.ec2LaunchTemplates."${builderNetwork.name}-template";
            # launchTemplateName = "${builderNetwork.name}-template";
            version = "$Latest";
          };
          overrides = lib.concatMap overridesBySubnet availableSubnets;
          # overrides =
          #   lib.concatMap
          #     (subnet:
          #     subnet
          #       builtins.map
          #         (instanceType: {
          #           inherit instanceType;
          #           weightedCapacity = 1.;
          #           subnetId = subnet;
          #         })
          #         builderNetwork.aws.instanceTypes
          #     )
          #     allSubnets;
        }
      ];
      # spotPrice = "0.08";
      inherit (builderNetwork.aws) spotMaxTotalPrice;
      # "ValidFrom": "2021-10-05T14:20:35Z",
      # "ValidUntil": "2022-10-05T14:20:35Z",
      # terminateInstancesWithExpiration = false;
    };
}
