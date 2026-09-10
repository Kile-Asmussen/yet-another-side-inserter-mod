#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"


function compile() {
    (
        git add --all
        git archive --worktree-attributes $(git stash create) --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip
        git gc --prune=now
    ) >/dev/null 2>/dev/null
}

function restore-list() {
    mv ~/.factorio/mods/mod-list.json~ ~/.factorio/mods/mod-list.json
}

function include() {
    local JQ="if any(.mods[]; .name == \"$NAME\") then . else .mods += [{ name: \"$NAME\", enabled: true }] end"
    cp ~/.factorio/mods/mod-list.json ~/.factorio/mods/mod-list.json~
    jq "$JQ" ~/.factorio/mods/mod-list.json~ > ~/.factorio/mods/mod-list.json
}

function exclude() {
    local JQ="del(.mods[] | select(.name == \"$NAME\"))"
    cp ~/.factorio/mods/mod-list.json ~/.factorio/mods/mod-list.json~
    jq "$JQ" ~/.factorio/mods/mod-list.json~ > ~/.factorio/mods/mod-list.json
}

function clean() {
    rm -rf ${NAME}_*
}

function uninstall() {
    rm -rf ~/.factorio/mods/${NAME}_*
    exclude
}

function inspect() {
    if [[ ! -f $NAME_VERSION.zip ]]; then compile; fi
    unzip -o $NAME_VERSION.zip >& /dev/null
}

function install() {
    if [[ ! -f $NAME_VERSION.zip ]]; then compile; fi
    uninstall
    cp -f $NAME_VERSION.zip ~/.factorio/mods/
    include
}

function link() {
    uninstall
    mkdir -p ~/.factorio/mods/$NAME_VERSION/
    for file in $(
        git ls-files \
        | git check-attr --stdin export-ignore \
        | rg -e '^([^:]+):.*unspecified' -r "\$1"
    ); do
        mkdir -p $(dirname ~/.factorio/mods/$NAME_VERSION/$file)
        ln ./$file ~/.factorio/mods/$NAME_VERSION/$file
    done
    include
}

for arg in $@; do
    $arg
done

if [[ $# -eq 0 ]]; then
    compile
fi