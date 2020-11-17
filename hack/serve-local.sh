#!/usr/bin/env bash

: "${PODMAN:=podman}"

command -v ${PODMAN} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN} command.  Aborting."; exit 1; }

: "${BOX_NAME:=box}"

: "${WORKING_DIR:=../docs}"

: "${POD_NAME:=podman_jekyll}"

${PODMAN} run -d \
              --volume="${WORKING_DIR}:/srv/jekyll" \
              jekyll/jekyll:3.8 mkdir _site .jekyll-cache
${PODMAN} run -d \
              --volume="${WORKING_DIR}:/srv/jekyll" \
              jekyll/jekyll:3.8 touch Gemfile.lock

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
              jekyll/jekyll:3.8 jekyll serve --incremental --trace

echo ""

echo "Access to the app: http://localhost:4000"
