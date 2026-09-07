#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"

rm -f $NAME_VERSION.zip

git archive --worktree-attributes HEAD --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip

if [[ $1 == install ]]; then
    cp -f  $NAME_VERSION.zip ~/.factorio/mods/
fi