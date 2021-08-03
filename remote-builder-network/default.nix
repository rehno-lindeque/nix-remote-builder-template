{ lib
, linkFarm
, nixops
, writeShellScriptBin
, networkName
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
              "${networkName}-help" = ''
                echo 'GENERAL USAGE:'
                echo
                printf '${"\t"}${white}${networkName}-help${nc}''\t''\tdisplay this help message''\n'
                printf '${"\t"}${white}${networkName}-ops${nc}''\t''\tlike nixops, but for remote builder infrastructure''\n'
                echo
              '';
              "${networkName}-ops" = ''
                case $1 in
                  *)
                    NIXOPS_DEPLOYMENT=${networkName} \
                    ${nixops}/bin/nixops \
                      $1 \
                      "''${@:2}"
                esac
              '';
            }
          )
  );
in
linkFarm networkName
  (
    lib.attrValues
      (lib.mapAttrs (name: path: { name = "bin/${name}"; path = "${path}/bin/${name}"; }) scripts)
  )

