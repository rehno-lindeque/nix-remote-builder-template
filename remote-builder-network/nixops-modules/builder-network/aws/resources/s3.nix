{ config
, lib
, ...
}:

let
  builderNetwork = config.builderNetwork;
  s3Bucket = builderNetwork.binaryCache.s3Bucket;
in
lib.mkIf s3Bucket.provision
{
  resources.s3Buckets.${s3Bucket.name} = {
    inherit (builderNetwork.aws) region;
    name = s3Bucket.name;

    # Don't delete this bucket ever
    persistOnDestroy = true;

    # Not publicly available
    # You may want to also set PublicAccessBlock, not currently supported by nixops
    website.enabled = false;

    # Save on costs by automatically moving objects to long-term, infrequent access storage after 365 days
    lifeCycle = ''
      {
        "Rules": [
           {
             "Status": "Enabled",
             "Prefix": "",
             "Transitions": [
               {
                 "Days": 365,
                 "StorageClass": "GLACIER"
               }
             ],
             "ID": "Glacier",
             "AbortIncompleteMultipartUpload":
               {
                 "DaysAfterInitiation": 7
               }
           }
        ]
      }
    '';
  };
}
