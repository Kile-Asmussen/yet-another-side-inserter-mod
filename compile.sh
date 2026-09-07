#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"

rm -f ${NAME}_*.*.*.zip

function compile() {
    git archive --worktree-attributes $(git stash create) --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip &> /dev/null
    git gc --prune=now &> /dev/null
}

function clean() {
    rm -f ${NAME}_*
}

function uninstall() {
    rm -rf ~/.factorio/mods/${NAME}_*
}

function files() {
    if [[ ! -f $NAME_VERSION.zip ]]; then compile; fi
    unzip $NAME_VERSION.zip &> /dev/null
}

function install() {
    if [[ ! -f $NAME_VERSION.zip ]]; then compile; fi
    uninstall
    cp -f $NAME_VERSION.zip ~/.factorio/mods/
}

function link() {
    uninstall
    files
    ln -s . ~/.factorio/mods/$NAME_VERSION
}

for arg in $@; do
    $arg
done

if [[ $# -eq 0 ]]; then
    compile
fi