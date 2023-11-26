{ pkgs ? import <nixpkgs> {} }:

let dependencies = import ./.nix/dependencies.nix;

in pkgs.mkShell {
  buildInputs = dependencies;

  # fixes libstdc++ issues and libgl.so issues
  LD_LIBRARY_PATH = "${pkgs.stdenv.cc.cc.lib}/lib";
}
