{ networkName
, region
, zone
, ami
, instanceType
, spotInstancePrice
}:

let
  ec2SpotInstance = { resources, lib, ... }: {
    targetEnv = "ec2";
    ec2 = (
      {
        inherit instanceType region spotInstancePrice zone;
        associatePublicIpAddress = true;
        subnetId = resources.vpcSubnets."${networkName}-subnet";
        keyPair = resources.ec2KeyPairs."${networkName}-keypair".name;
        securityGroupIds = [ resources.ec2SecurityGroups."${networkName}-sg".name ];
        ebsInitialRootDiskSize = 30;
        instanceProfile = resources.iamRoles."${networkName}-role".name;
      } //
      lib.optionalAttrs (ami != null) {
        inherit ami;
      }
    );
  };
in
{
  builder = { resources, lib, ... }:
    ec2SpotInstance {
      inherit resources lib;
    };
}
