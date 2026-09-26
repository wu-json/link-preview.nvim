#!/usr/bin/env bash
set -euo pipefail

install_dir="${1:?Usage: setup-neovim-tests.sh INSTALL_DIR}"
snacks_revision=882c996cf28183f4d63640de0b4c02ec886d01f2
neovim_version=v0.11.5

download_archive() {
  local url="$1"
  local destination="$2"
  mkdir -p "$destination"
  curl --fail --silent --show-error --location --retry 2 "$url" \
    | tar -xz --strip-components=1 -C "$destination"
}

download_archive \
  "https://github.com/neovim/neovim/releases/download/$neovim_version/nvim-linux-x86_64.tar.gz" \
  "$install_dir/nvim"

download_archive \
  "https://github.com/folke/snacks.nvim/archive/$snacks_revision.tar.gz" \
  "$install_dir/snacks.nvim"
