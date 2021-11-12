[
  (self: super: {
    nix = self.nixFlakes;
    poetry = super.poetry;
    poetry2nix = super.poetry2nix;
  })
]
