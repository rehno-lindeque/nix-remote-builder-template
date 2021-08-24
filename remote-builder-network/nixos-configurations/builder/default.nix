{ flake
, ...
}:

{
  imports = [
    flake.nixosModules."${system}".builderNode
  ];
}
