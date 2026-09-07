{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      rust-overlay,
      nix-claude-code,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        overlays = [
          rust-overlay.overlays.default
        ];
        pkgs = import nixpkgs { inherit system overlays; };
      in
      {
        devShells.default =
          with pkgs;
          mkShell {
            nativeBuildInputs = [ bashInteractive ];

            shellHook = ''
              # nix develop shells will by default overwrite the $SHELL variable with a
              # non-interactive version of bash. The deviates from how nix-shell works.
              # This fix was taken from:
              #    https://discourse.nixos.org/t/interactive-bash-with-nix-develop-flake/15486
              #
              # See also: nixpkgs#5131 nixpkgs#6091
              export SHELL=${pkgs.bashInteractive}/bin/bash
              alias jq=jaq
            '';

            packages = with pkgs; [
              lua
              jaq
            ];
          };
      }
    );
}
