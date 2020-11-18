#!/usr/bin/env bash

: "${PODMAN:=podman}"

: "${REGISTRY:=docker.io}"

command -v ${PODMAN} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN} command.  Aborting."; exit 1; }

: "${WORKING_DIR:=../docs}"

: "${POD_NAME:=podman_jekyll}"

${PODMAN} run -d \
              --volume="${WORKING_DIR}:/srv/jekyll" \
              ${REGISTRY}/jekyll/jekyll:3.8 mkdir _site .jekyll-cache

POD_EXISTS=$(${PODMAN} ps -a --format {{.Names}} | grep "^${POD_NAME}")
if [ $? -eq 0 ]; then
    echo "Delete pod ${POD_NAME}"
    ${PODMAN} stop ${POD_NAME}
    ${PODMAN} rm ${POD_NAME}
fi

echo "Run pod ${POD_NAME}"
${PODMAN} run -d \
              -p 4000:4000 \
              --volume="${WORKING_DIR}:/srv/jekyll" \
              --name ${POD_NAME} \
              ${REGISTRY}/jekyll/jekyll:3.8 jekyll serve --incremental --trace
echo ""

echo "podman logs -f ${POD_NAME}"

echo ""

echo "Access to the app: http://localhost:4000"
