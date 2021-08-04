{ lib
, linkFarm
, writeShellScriptBin
, name
}:

let
  scripts = lib.fix (
    self:
        lib.mapAttrs writeShellScriptBin
          (
            let
              nc = "\\e[0m"; # No Color
              white = "\\e[1;37m";
            in
            {
              "${name}-help" = ''
                echo 'GENERAL USAGE:'
                echo
                printf '${"\t"}${white}${name}-help${nc}''\tdisplay this help message''\n'
                echo
              '';
            }
          )
  );
in
linkFarm name
  (
    lib.attrValues
      (lib.mapAttrs (name: path: { name = "bin/${name}"; path = "${path}/bin/${name}"; }) scripts)
  )

