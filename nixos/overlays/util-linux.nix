{
  config,
  pkgs,
  lib,
  pkgs-stable,
  ...
}: {
  nixpkgs.overlays = [
    (self: super: {
      util-linux = pkgs-stable.util-linux;
    })
  ];
}
