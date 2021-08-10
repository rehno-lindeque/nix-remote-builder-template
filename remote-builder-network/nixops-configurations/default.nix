{ flake
, ...
}:

{
  builderNetwork = {
    aws.region = "us-east-1";
    aws.zone = "us-east-1b";
    nixosConfiguration = flake.nixosConfigurations.builder;
    binaryCache.url = "s3://builder?region=us-east-1";
    binaryCache.publicKey = "builder:/0000000000000000000000000000000000000000000";
  };
}
