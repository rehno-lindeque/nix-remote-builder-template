{ pkgs
, lib
, resources
, config
, nodes
, ...
}:

let
  binaryCacheUrl = s3://nix-build?region=us-east-1;
  binaryCachePrivateKey = config.deployment.keys.binary-cache-key.path;
  binaryCachePublicKey = config.builderNetwork.binaryCachePublicKey;

  # See https://nixos.org/manual/nix/unstable/advanced-topics/post-build-hook.html
  uploadToS3Cache = pkgs.writeShellScript "upload-to-s3-cache.sh" ''
    set -eu
    set -f # disable globbing
    export IFS=' '

    echo "Signing" $OUT_PATHS
    echo nix store sign \
      --key-file ${binaryCachePrivateKey} \
      $OUT_PATHS
    nix store sign-paths \
      --key-file ${binaryCachePrivateKey} \
      $OUT_PATHS

    echo "Uploading" $OUT_PATHS
    echo exec ${pkgs.ts}/bin/ts nix copy \
      --to 's3://nix-build?region=us-east-1&parallel-compression' \
      $OUT_PATHS
    exec ${pkgs.ts}/bin/ts nix copy \
      --to 's3://nix-build?region=us-east-1&parallel-compression' \
      $OUT_PATHS
  '';
in
{
  networking.firewall = {
    enable = true;
  };

  services = {
    openssh = {
      enable = true;
      # Larger MaxAuthTries helps to avoid ssh 'Too many authentication failures' issue
      # See https://github.com/NixOS/nixops/issues/593#issue-203407250
      extraConfig = ''
        MaxAuthTries 20
      '';
      openFirewall = true;
    };
  };

  nixpkgs.config.allowUnfree = true;

  boot.loader.grub.device = "/dev/xvda";
  fileSystems."/" = {
    label = "nixos";
    fsType = "ext4";
  };

  environment.systemPackages =
    with pkgs;
    [
    ];

  nix.sshServe = {
    enable = true;
    keys = [
      # Add your own public key here
    ];
    protocol = "ssh-ng";
  };

  # Note that the nix package affects nix.sshServe
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    post-build-hook = ${uploadToS3Cache}
    experimental-features = nix-command flakes
  '';

  nix.binaryCaches = [
    http://cache.nixos.org/
  ];
  nix.binaryCachePublicKeys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    binaryCachePublicKey
  ];
}

