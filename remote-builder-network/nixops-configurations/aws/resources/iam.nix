# { networkName
# , region
# , zone
# }:
{ config
, ...
}:

let
  builderNetwork = config.builderNetwork;
in
{
  resources.iamRoles."${builderNetwork.name}-role" = {
    inherit (builderNetwork) region;
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
            "arn:aws:s3:::nix-build"
            "arn:aws:s3:::nix-build/*"
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
            "arn:aws:s3:::nix-build"
            "arn:aws:s3:::nix-build/*"
          ];
        }
      ];
    };
  };
}

