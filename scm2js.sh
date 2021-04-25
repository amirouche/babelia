#!/bin/sh

set -xe

docker run -v $(pwd):/mnt --rm -it schemers/gambit:head gsc -:r7rs -target js -exe /mnt/$1
tail -n +2 $(basename $1 .scm) > "$(basename $1 .scm).js"
rm -f $(basename $1 .scm)
