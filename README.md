# vim-nixhash

This neovim plugin automates the common TOFU (trust on first use) workflow for fetcher hashes in nix.

More precisely, when I need to provide nix with the sha256 of a dependency, I usually write
`sha256 = "0000000000000000000000000000000000000000000000000000";` (with
`52a0`), then run a command to build the file: `nix-build -A foo`,
`home-manager switch`, `nixos-rebuild switch` or a variation. I can then look
for nix's error message:
```
hash mismatch in fixed-output derivation '/nix/store/f00ag9rzy2w08f9yv6kb225si1ia1kzn-source':
  wanted: sha256:0000000000000000000000000000000000000000000000000000
  got:    sha256:10v6wmhq3ml13zx9qj9fr3j2pbwzwn4s3lapnhxvxd0kmlx7isw2
```
I replace 0000000000000000000000000000000000000000000000000000 by 10v6wmhq3ml13zx9qj9fr3j2pbwzwn4s3lapnhxvxd0kmlx7isw2 and I'm done!

This plugin provides one command to automate this workflow: `:NixHash`. It runs
a shell command, parses its output for hash mismatch error messages and
performs the replacement for you.
For example if you have a file `foo.nix`:
```nix
with import <nixpkgs> {};
fetchFromGitHub {
  owner = "symphorien";
  repo = "nix-du";
  rev = "v0.3.0";
  # should be fixed
  sha256 = "1000000000000000000000000000000000000000000000000000";
}
```
and run: `:NixHash nix-build foo.nix` then the plugin operates this fix:
```diff
diff --git a/fixtures/foo.nix b/fixtures/foo.nix
index 4322ac9..64ecae6 100644
--- a/foo.nix
+++ b/foo.nix
@@ -4,5 +4,5 @@ fetchFromGitHub {
   repo = "nix-du";
   rev = "v0.3.0";
   # should be fixed
-  sha256 = "1000000000000000000000000000000000000000000000000000";
+  sha256 = "1x6qpivxbn94034jfdxb97xi97fhcdv2z7llq2ccfc80mgd0gz8l";
 }
```

# Specifics

* Requires neovim
* Only replaces hashes in loaded buffers
* If you use the same fake sha256 (for example all zeros) in several places, they will not be fixed
* probably needs some adapation for SRI hashes
