{ lib
, ...
}:

{
  options = with lib.types; {
    network = lib.mkOption { type = attrsOf anything; };
    resources = lib.mkOption { type = attrsOf anything; };
    deployments = lib.mkOption { type = attrsOf anything; };
    nixpkgs = lib.mkOption { type = anything; };
  };
}
