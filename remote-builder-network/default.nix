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
                echo 'ADDITIONAL COMMANDS:'
                echo
                printf '${"\t"}${networkName}-ops ${white}create --flake .${nc}''\t''\tto get started''\n'
                printf '${"\t"}${networkName}-ops ${white}build${nc} INSTALLABLES...''\tbuild nix derivations on remote builder''\n'
                printf '${"\t"}${networkName}-ops ${white}up${nc}''\t''\t''\t''\tdeploy remote builder''\n'
                printf '${"\t"}${networkName}-ops ${white}down${nc}''\t''\t''\ttear down remote builder''\n'
                echo
              '';
              "${networkName}-ops" = ''
                case $1 in
                  'build' )
                    NIXOPS_DEPLOYMENT=${networkName} \
                    ${nixops}/bin/nixops info --plain --no-eval |
                      cut -f 1,5 --output-delimiter=$'\n' |
                      grep -A 1 '^builder-1$' |
                      tail -n 1 | {
                        read ip_address
                        echo "Build on remote builder-1 (IP: $ip_address)"
                        nix build -L ''${@:2} --store "ssh-ng://nix-ssh@$ip_address"
                      }
                      ;;
                  'up' )
                    ${networkName}-ops deploy --include builder-1
                    ;;
                  'down' )
                    ${networkName}-ops destroy --include builder-1
                    ;;
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

