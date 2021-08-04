# Nix remote builder templates

This template is currently for my own use, but you are welcome to try it.

A deployment will obviously incur charges, so make sure you understand what you are doing when deploying this. It is your own responsibility to make sure that the generated template is correct.

## Instantiating the templates

To create a remote builder network, use the following command.

```
nix flake init -t github:rehno-lindeque/nix-remote-builder-template#remote-builder-network
```

## Developing the templates

Run `nix develop` to get started. 

If you don't have nix 2.0: `nix-shell -p nixFlakes --run 'nix develop'`.

Make sure that `experimental-features = nix-command flakes` is turned on, since this is a flake.
