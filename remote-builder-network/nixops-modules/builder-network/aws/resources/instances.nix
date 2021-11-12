{ config
, lib
, ...
}:
let
  builderNetwork = config.builderNetwork;
  reference = resource:
    lib.mapAttrs
      (fieldName: _: { ref = "resources/${resource._type}/${resource._name}"; inherit fieldName; }) resource;
in
{
  # resources.ec2Instances."${builderNetwork.name}-instances" = { resources, lib, ... }: {
  #   inherit (builderNetwork.aws) region;
  #   awsConfig = {
  #     DryRun = true;
  #     MinCount = 1;
  #     MaxCount = 1;
  #     InstanceType = "t2.micro";
  #     ImageId = (import "${config.nixpkgs}/nixos/modules/virtualisation/ec2-amis.nix").latest."${builderNetwork.aws.region}".hvm-ebs;
  #     SubnetId = (reference resources.vpcSubnets."${builderNetwork.name}-subnet").subnetId;

  #     # inherit instanceType region spotInstancePrice zone;
  #     # associatePublicIpAddress = true;
  #     # subnetId = resources.vpcSubnets."${networkName}-subnet";
  #     # keyPair = resources.ec2KeyPairs."${networkName}-keypair".name;
  #     # securityGroupIds = [ resources.ec2SecurityGroups."${networkName}-sg".name ];
  #     # ebsInitialRootDiskSize = 30;
  #     # instanceProfile = resources.iamRoles."${networkName}-role".name;
  #   };
  # };
}
