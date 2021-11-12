{ pkgs ? import <nixpkgs> { overlays = import ./overlays.nix; }
}:

let
  remote-builder-template = pkgs.callPackage ./. {
    name = "remote-builder-template";
  };

in
pkgs.mkShell {
  buildInputs = with pkgs; [
    nix
    nixpkgs-fmt
    direnv
    remote-builder-template

    # dependencies for updating nixops
    poetry
    poetry2nix.cli
  ];
  shellHook =
    let
      nc = "\\e[0m"; # No Color
      white = "\\e[1;37m";
    in
     ''
        clear -x
        printf "${white}"
        echo "--------------------------------"
        echo "Template development environment"
        echo "--------------------------------"
        printf "${nc}"
        echo
        ${remote-builder-template}/bin/remote-builder-template-help

        # Hook up direnv
        echo
        if [ -n "$BASH_VERSION" ]; then
          eval "$(direnv hook bash)"
        elif [ -n "$ZSH_VERSION" ]; then
          eval "$(direnv hook zsh)"
        else
          echo "Unknown terminal shell"
        fi
    '';
}
