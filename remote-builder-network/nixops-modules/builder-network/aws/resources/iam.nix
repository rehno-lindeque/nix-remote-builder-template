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
      ];
    };
  };
}

