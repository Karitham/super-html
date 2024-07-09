{
  description = "Flake for super-html";
  inputs = {
    zig2nix.url = "github:Cloudef/zig2nix";
  };

  outputs = {zig2nix, ...}: let
    flake-utils = zig2nix.inputs.flake-utils;
  in (flake-utils.lib.eachDefaultSystem (system: let
    # Zig flake helper
    # Check the flake.nix in zig2nix project for more options:
    # <https://github.com/Cloudef/zig2nix/blob/master/flake.nix>
    env = zig2nix.outputs.zig-env.${system} {};
    system-triple = env.lib.zigTripleFromString system;
  in
    with builtins;
    with env.lib;
    with env.pkgs.lib; rec {
      # nix build .#target.{zig-target}
      # e.g. nix build .#target.x86_64-linux-gnu
      packages.target = genAttrs allTargetTriples (target:
        env.packageForTarget target {
          pname = "super-html";
          src = cleanSource ./.;

          # Smaller binaries and avoids shipping glibc.
          zigPreferMusl = true;

          # This disables LD_LIBRARY_PATH mangling, binary patching etc...
          # The package won't be usable inside nix.
          zigDisableWrap = true;

          zigBuildFlags = ["-Doptimize=ReleaseFast"];
        });

      # nix build .
      packages.default = packages.target.${system-triple}.override {
        # Prefer nix friendly settings.
        zigPreferMusl = false;
        zigDisableWrap = false;

        zigBuildFlags = ["-Doptimize=ReleaseFast"];
      };
    }));
}
