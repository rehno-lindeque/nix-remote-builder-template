{ config
, ...
}:
let
  builderNetwork = config.builderNetwork;
  s3Bucket = builderNetwork.binaryCache.s3Bucket;
in
{
  resources.iamRoles."${builderNetwork.name}-role" = {
    inherit (builderNetwork.aws) region;
    policy = builtins.toJSON {
      Statement = [
        # Read from nix binary cache
        {
          Effect = "Allow";
          Action = [
            "s3:GetObject"
            "s3:GetBucketLocation"
          ];
          Resource = [
            "arn:aws:s3:::${s3Bucket.name}"
            "arn:aws:s3:::${s3Bucket.name}/*"
          ];
        }
        # Upload to nix binary cache
        {
          Effect = "Allow";
          Action = [
            "s3:AbortMultipartUpload"
            "s3:GetBucketLocation"
            "s3:GetObject"
            "s3:ListBucket"
            "s3:ListBucketMultipartUploads"
            "s3:ListMultipartUploadParts"
            "s3:PutObject"
          ];
          Resource = [
            "arn:aws:s3:::${s3Bucket.name}"
            "arn:aws:s3:::${s3Bucket.name}/*"
          ];
        }
      ] ++ builderNetwork.aws.extraIamStatements;
    };
  };

  resources.iamRoles."${builderNetwork.name}-fleet-role" = {
    inherit (builderNetwork.aws) region;
    name = "${builderNetwork.name}-fleet-role";
    assumeRolePolicy = builtins.toJSON {
      # See https://docs.aws.amazon.com/batch/latest/userguide/spot_fleet_IAM_role.html#spot-fleet-roles-cli
      Statement = [
        {
          Sid = "";
          Effect = "Allow";
          Principal = {
            Service = "spotfleet.amazonaws.com";
          };
          Action = "sts:AssumeRole";
        }
      ];
    };

    policy = builtins.toJSON {
      # See arn:aws:iam::aws:policy/service-role/AmazonEC2SpotFleetTaggingRole in the aws console
      Statement = [
        {
          Effect = "Allow";
          Action = [
            "ec2:DescribeImages"
            "ec2:DescribeSubnets"
            "ec2:RequestSpotInstances"
            "ec2:TerminateInstances"
            "ec2:DescribeInstanceStatus"
            "ec2:CreateTags"
            "ec2:RunInstances"
          ];
          Resource = [
            "*"
          ];
        }
        {
          Effect = "Allow";
          Action = "iam:PassRole";
          Condition =
            {
              StringEquals = {
                "iam:PassedToService" = [
                  "ec2.amazonaws.com"
                  "ec2.amazonaws.com.cn"
                ];
              };
            };
          Resource = [
            "*"
          ];
        }
        {
          Effect = "Allow";
          Action = [
            "elasticloadbalancing:RegisterInstancesWithLoadBalancer"
          ];
          Resource = [
            "arn:aws:elasticloadbalancing:*:*:loadbalancer/*"
          ];
        }
        {
          Effect = "Allow";
          Action = [
            "elasticloadbalancing:RegisterTargets"
          ];
          Resource = [
            "arn:aws:elasticloadbalancing:*:*:*/*"
          ];
        }
      ];
    };
  };
}
