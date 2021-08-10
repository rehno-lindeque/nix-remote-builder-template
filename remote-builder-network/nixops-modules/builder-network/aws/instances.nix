{ networkName
, region
, zone
}:

let
  ec2SpotInstance = { instanceType ? "t2.micro", spotInstancePrice ? 1, resources, lib, ... }: {
    targetEnv = "ec2";
    ec2 = {
      inherit instanceType region spotInstancePrice zone;
      associatePublicIpAddress = true;
      subnetId = resources.vpcSubnets."${networkName}-subnet";
      keyPair = resources.ec2KeyPairs."${networkName}-keypair".name;
      securityGroupIds = [ resources.ec2SecurityGroups."${networkName}-sg".name ];
      ebsInitialRootDiskSize = 30;
      instanceProfile = resources.iamRoles."${networkName}-role".name;
    };
  };
in
{
  builder = { resources, lib, ... }:
    ec2SpotInstance {
      inherit resources lib;
    };
}
