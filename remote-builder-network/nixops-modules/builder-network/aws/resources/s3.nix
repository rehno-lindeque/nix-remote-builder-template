{ config
, ...
}:

let
  builderNetwork = config.builderNetwork;
in
{
  resources.s3Buckets.nix-build = {
    inherit (builderNetwork.aws) region;
    name = "nix-build";

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
