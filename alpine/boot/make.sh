#!/bin/sh

rm -f headless.apkovl.tar.gz
tar czvf headless.apkovl.tar.gz usr etc

if [ -d "$1" ]; then
	echo "Copying to $1"
	cp headless.apkovl.tar.gz "$1"
	cp headless.txt "$1"
fi
