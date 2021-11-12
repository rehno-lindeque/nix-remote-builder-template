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

    # TODO: fix security group ids (update launch template resource)
    # securityGroupIds = [ resources.ec2SecurityGroups."${builderNetwork.name}-sg" ];

    ebsInitialRootDiskSize = 30;
    instanceProfile = resources.iamRoles."${builderNetwork.name}-role".name;
    instanceType = ""; # TODO: currently necessary to prevent nix from defaulting to m1.small
    ebsOptimized = false;
  };
  resources.awsSpotFleets."${builderNetwork.name}-fleet" = { resources, lib, ... }: {
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
        overrides = [
          {
            instanceType = "m1.small";
            weightedCapacity = 1.;
            # spotPrice = "0.05";
          }
          {
            instanceType = "m3.medium";
            weightedCapacity = 1.;
            # spotPrice = "0.05";
          }
          {
            instanceType = "m1.medium";
            weightedCapacity = 1.;
            # spotPrice = "0.05";
          }
        ];
      }
    ];
    # spotPrice = "0.08";
    spotMaxTotalPrice = "1.0";
    # "ValidFrom": "2021-10-05T14:20:35Z",
    # "ValidUntil": "2022-10-05T14:20:35Z",
    # terminateInstancesWithExpiration = false;
  };
}
