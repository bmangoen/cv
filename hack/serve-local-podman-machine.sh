#!/bin/bash

: "${PODMAN_MACHINE:=podman-machine}"
: "${PODMAN:=podman}"

command -v ${PODMAN_MACHINE} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN_MACHINE} command.  Aborting."; exit 1; }
command -v ${PODMAN} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN} command.  Aborting."; exit 1; }

: "${BOX_NAME:=box}"

: "${BOX_DATA_DIR:=/home/tc/data}"
: "${BOX_ISO_URL:=https://github.com/snowjet/boot2podman-fedora-iso/releases/download/d1bb19f/boot2podman-fedora.iso}"

BOX_EXISTS=$(${PODMAN_MACHINE} ls | grep "^${BOX_NAME}")
if [ $? -ne 0 ]
then
  ${PODMAN_MACHINE} create \
    --virtualbox-boot2podman-url ${BOX_ISO_URL} \
    --virtualbox-memory="4096" \
    ${BOX_NAME}
fi

BOX_STATUS=$(${PODMAN_MACHINE} status ${BOX_NAME})

${PODMAN_MACHINE} scp -r -q "../docs/" "${BOX_NAME}:${BOX_DATA_DIR}/"
${PODMAN_MACHINE} ssh ${BOX_NAME} "mkdir -p ${BOX_DATA_DIR}/_site; \
                        mkdir -p ${BOX_DATA_DIR}/.jekyll-cache;"
${PODMAN_MACHINE} ssh ${BOX_NAME} "chcon -R -t svirt_sandbox_file_t ${BOX_DATA_DIR}"

eval $(${PODMAN_MACHINE} env ${BOX_NAME} --varlink)

${PODMAN} run -d -p 4000:4000 --volume="${BOX_DATA_DIR}:/srv/jekyll" jekyll/jekyll:3.8 jekyll serve --trace

echo "http://$(${PODMAN_MACHINE} ip ${BOX_NAME}):4000"
echo "eval \$(${PODMAN_MACHINE} env ${BOX_NAME} --varlink)"