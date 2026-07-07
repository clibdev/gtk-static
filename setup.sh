#!/bin/bash
set -eo pipefail

if [[ ! $1 =~ ^(build-image|build-lib)$ ]]; then
  echo 'Available arguments: build-image, build-lib'
  exit 1
fi

if [[ $1 == build-image ]]; then
  docker build -t gtk scripts

  exit 0
fi

if [[ $1 == build-lib ]]; then
  docker run --rm -v ./:/app gtk scripts/compile.sh
  sudo chown -R $USER:$USER build

  exit 0
fi
