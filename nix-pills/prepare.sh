#!/usr/bin/env bash

useradd -m pills
mkdir -m 0755 /nix && chown pills /nix

sudo -s -u pills
cd "$HOME"
