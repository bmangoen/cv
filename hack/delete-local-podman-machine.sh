#!/usr/bin/env bash

: "${PODMAN_MACHINE:=podman-machine}"

command -v ${PODMAN_MACHINE} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN_MACHINE} command.  Aborting."; exit 1; }

: "${BOX_NAME:=box}"

${PODMAN_MACHINE} rm ${BOX_NAME} -y