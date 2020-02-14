#!/bin/bash


WORKFLOWS="$( cd "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )/workflows"
TMPDIR=$(mktemp -d)
EXDIR=$(mktemp -d)
curl -L -o $TMPDIR/actions.zip  https://github.com/elementary/actions/archive/master.zip

unzip $TMPDIR/actions.zip -d $EXDIR

echo "Copying $EXDIR/actions-master/* to $WORKFLOWS/"
cp -r $EXDIR/actions-master/* $WORKFLOWS/
