{ config
, lib
, ...
}:

let
  builderNetwork = config.builderNetwork;
  managedS3Bucket = builderNetwork.binaryCache.managedS3Bucket;
in
lib.mkIf managedS3Bucket.enable
{
  resources.s3Buckets.${managedS3Bucket.name} = {
    inherit (builderNetwork.aws) region;
    name = managedS3Bucket.name;

    # Don't delete this bucket ever
    persistOnDestroy = true;

    # Not publicly available
    # You may want to also set PublicAccessBlock, not currently supported by nixops
    website.enabled = false;

    # Save on costs by automatically moving objects to long-term, infrequent access storage after 30 days
    lifeCycle = ''
      {
        "Rules": [
           {
             "Status": "Enabled",
             "Prefix": "",
             "Transitions": [
               {
                 "Days": 30,
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
