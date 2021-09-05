with import <nixpkgs> {};
fetchFromGitHub {
  owner = "symphorien";
  repo = "nix-du";
  rev = "v0.3.0";
  # should be fixed
  sha256 = "1000000000000000000000000000000000000000000000000000";
}
