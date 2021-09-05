with import <nixpkgs> {};
let
  first = fetchFromGitHub {
    owner = "symphorien";
    repo = "nix-du";
    rev = "v0.3.2";
    # should be fixed
    sha256 = "0000000000000000000000000000000000000000000000000000";
  };
  second = import ./foo.nix;
  third = fetchFromGitHub {
    owner = "symphorien";
    repo = "nix-du";
    rev = "v0.3.1";
    # duplicate, should stay as is
    sha256 = "0100000000000000000000000000000000000000000000000000";
  };
  fourth = fetchFromGitHub {
    owner = "symphorien";
    repo = "nix-du";
    rev = "v0.3.1";
    # duplicate, should stay as is
    sha256 = "0100000000000000000000000000000000000000000000000000";
  };
in
buildEnv {
  name = "test";
  paths = [ first second third fourth ];
}
