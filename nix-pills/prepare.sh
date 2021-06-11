#!/usr/bin/env bash

user=nix

useradd -m $user
mkdir -m 0755 /nix && chown $user /nix

sudo -s -u $user
cd "$HOME" || exit 1
