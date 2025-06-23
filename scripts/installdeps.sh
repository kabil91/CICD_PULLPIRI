#!/bin/bash

common_packages=(
  libdbus-1-dev
  git-all
  make
  gcc
  docker.io 
  protobuf-compiler 
  build-essential 
  pkg-config 
  curl 
  libssl-dev 
  nodejs
)
specific_packages=()

#apt-get update && apt-get install --no-install-recommends "${common_packages[@]}" "${specific_packages[@]}"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "${common_packages[@]}" "${specific_packages[@]}"

if [[ "$FAILED" -gt 0 ]]; then
    echo "::error ::Package installation failed! Check logs."
    exit 1
fi

exit 0
