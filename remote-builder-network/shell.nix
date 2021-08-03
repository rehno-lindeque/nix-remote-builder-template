{ pkgs ? import <nixpkgs> { overlays = import ./overlays.nix; }
, networkName ? "builder"
}:

let
  builder = pkgs.callPackage ./. {
    inherit networkName;
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nix
    nixops
    nixpkgs-fmt
    builder
    direnv
  ];
  shellHook =
    let
      nc = "\\e[0m"; # No Color
      white = "\\e[1;37m";
    in
      ''
        echo
        printf "${white}"
        echo "-------------------------------------"
        echo "Remote builder deployment environment"
        echo "-------------------------------------"
        printf "${nc}"
        echo
        ${builder}/bin/${networkName}-help

        # Hook up direnv
        echo
        if [ -n "$BASH_VERSION" ]; then
          eval "$(direnv hook bash)"
        elif [ -n "$ZSH_VERSION" ]; then
          eval "$(direnv hook zsh)"
        else
          echo "Unknown shell"
        fi

        export NIXOPS_STATE=$(pwd)/secret/localstate.nixops
    '';
}
