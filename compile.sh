#! /usr/bin/env bash

VERSION=$(jq -r '.version' < info.json)
NAME=$(jq -r '.name' < info.json)

git archive --worktree-attributes HEAD -o "${NAME}_${VERSION}.zip"