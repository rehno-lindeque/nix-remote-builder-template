{ pkgs ? import <nixpkgs> { overlays = import ./overlays.nix; }
, networkName ? "builder"
, networkOps ? pkgs.callPackage ./. { inherit networkName; }
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nix
    nixops
    nixpkgs-fmt
    networkOps
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
        echo "---------------------------------------------"
        echo "Remote builder network deployment environment"
        echo "---------------------------------------------"
        printf "${nc}"
        echo
        ${networkOps}/bin/${networkName}-help

        # Hook up direnv
        echo
        if [ -n "$BASH_VERSION" ]; then
          eval "$(direnv hook bash)"
        elif [ -n "$ZSH_VERSION" ]; then
          eval "$(direnv hook zsh)"
        else
          echo "Unknown terminal shell"
        fi

        export NIXOPS_STATE=$(pwd)/secret/localstate.nixops
    '';
}
