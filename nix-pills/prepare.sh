#!/usr/bin/env bash

mkdir -m 0755 /nix && chown pills /nix

useradd -m pills

sudo -s -u pills
cd "$HOME"
