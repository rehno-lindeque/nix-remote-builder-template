# { networkName
# , region
# , zone
# , ami
# , instanceType
# , spotInstancePrice
# }:

# # TODO rename to targets.nix or merge with caller

# let
#   ec2SpotInstance = { nodes, lib, ... }: {
#     targetEnv = "ec2";
#     ec2 = (
#       {
#         inherit instanceType region spotInstancePrice zone;
#         associatePublicIpAddress = true;
#         # subnetId = resources.vpcSubnets."${networkName}-subnet";
#         subnetId = resources.vpcSubnets."${networkName}-subnet";
#         keyPair = resources.ec2KeyPairs."${networkName}-keypair".name;
#         securityGroupIds = [ resources.ec2SecurityGroups."${networkName}-sg".name ];
#         ebsInitialRootDiskSize = 30;
#         instanceProfile = resources.iamRoles."${networkName}-role".name;
#       } //
#       lib.optionalAttrs (ami != null) {
#         inherit ami;
#       }
#     );
#   };

#   ec2SpotFleetTarget = { resources, lib, ... }: {
#     targetEnv = "ec2-target";
#     ec2.target = {
#       spotFleetRequestId = resources.awsSpotFleetRequest."${networkName}-fleet";
#     };
#   };
# in
# {
#   builder = { resources, lib, ... }:
#     ec2SpotInstance {
#       inherit resources lib;
#     };
#   builderTarget = { resources, lib, ... }:
#     ec2SpotFleetTarget {
#       inherit resources lib;
#     };
# }
