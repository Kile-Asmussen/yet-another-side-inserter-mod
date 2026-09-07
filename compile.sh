#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"

rm -f ${NAME}_*.*.*.zip

if [[ $* != *clean* ]] && [[ $* != *uninstall* ]]; then
    git archive --worktree-attributes HEAD --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip &> /dev/null
fi

if [[ $* == *install* ]] && [[ $* != *uninstall* ]]; then
    cp -f  $NAME_VERSION.zip ~/.factorio/mods/
fi

if [[ $* == *unzip* ]] then
    unzip $NAME_VERSION.zip &> /dev/null
fi

if [[ $* == *uninstall* ]]; then
    rm -f ~/.factorio/mods/${NAME}_*.*.*.zip
fi