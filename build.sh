#!/bin/bash
# Build a container if necessary and run the app build

cd -P -- "$(dirname -- "$0")"

if [ ! -s shared/.netrc ]; then
  echo "shared/.netrc file is not set up. See README.md for more info."
  exit
fi

if [ ! -s shared/build_vars.sh ]; then
  echo "shared/build_vars.sh file is not set up. See README.md for more info."
  exit
fi

if [ "$1" == 'clean' ]; then
  docker image rm consected/restructure-build --force
fi

if [ -z "$(docker images | grep consected/restructure-build)" ]; then
  docker build . -t consected/restructure-build
fi

docker run --volume="$(pwd)/shared:/shared" --volume="$(pwd)/output:/output" consected/restructure-build
