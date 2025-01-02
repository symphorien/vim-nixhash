#!/bin/sh
exec nvim -V/tmp/nvim.log -u fixtures/init.vim fixtures/mismatch.nix
