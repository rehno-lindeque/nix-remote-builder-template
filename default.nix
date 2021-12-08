{ lib
, linkFarm
, writeShellScriptBin
, name
, awscli
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
                printf '${"\t"}${white}${name}-aws-offerings${nc}''\tfetch up-to-date AWS EC2 offerings (used to update template)''\n'
                echo
              '';
              "${name}-aws-offerings" = ''
                ${awscli}/bin/aws ec2 describe-instance-type-offerings \
                  --region us-east-1 \
                  --location-type availability-zone
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

