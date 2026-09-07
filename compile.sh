#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)
NAME_VERSION="${NAME}_${VERSION}"

git archive --worktree-attributes HEAD --prefix=$NAME_VERSION/ -o $NAME_VERSION.zip