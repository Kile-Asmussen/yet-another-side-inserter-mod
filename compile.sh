#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"

rm -f $NAME_VERSION.zip
rm -rf $NAME_VERSION

git archive --worktree-attributes HEAD --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip

if [[ $* == *install* ]]; then
    cp -f  $NAME_VERSION.zip ~/.factorio/mods/
fi

if [[ $* == *unzip* ]]; then
    unzip $NAME_VERSION.zip
fi