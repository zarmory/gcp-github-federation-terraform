let
  commit = "b30c68669df77d981ce4aefd6b9d378563f6fc4e"; # nixos-23.05 @ 2023-08-18
  pkgsSrc = builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/${commit}.tar.gz";
    # Use "nix-prefetch-url --unpack <url>" to calculate sha256
    # Or set to empty and wait for the error to tell you the right one
    sha256 = "1k87lc9cxsrnpyjr0w56pqs5h9zgpyipxbiypmf3s98wlhscdwxm";
  };
  pkgs = import pkgsSrc {};
in

with pkgs; [
  gnumake
  terraform
  google-cloud-sdk
  envsubst
]
