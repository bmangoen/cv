#!/usr/bin/env bash

: "${PODMAN_MACHINE:=podman-machine}"
: "${PODMAN:=podman}"

command -v ${PODMAN_MACHINE} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN_MACHINE} command.  Aborting."; exit 1; }
command -v ${PODMAN} >/dev/null 2>&1 || { echo >&2 "can't find ${PODMAN} command.  Aborting."; exit 1; }

: "${BOX_NAME:=box}"

: "${BOX_DATA_DIR:=/home/tc/data}"
: "${BOX_ISO_URL:=https://github.com/snowjet/boot2podman-fedora-iso/releases/download/d1bb19f/boot2podman-fedora.iso}"
: "${BOX_VM_MEMORY:=4096}"

: "${BOX_POD_NAME:=podman_machine_box}"

BOX_EXISTS=$(${PODMAN_MACHINE} ls | grep "^${BOX_NAME}")
if [ $? -ne 0 ]; then
  ${PODMAN_MACHINE} create \
    --virtualbox-boot2podman-url ${BOX_ISO_URL} \
    --virtualbox-memory="${BOX_VM_MEMORY}" \
    ${BOX_NAME}
fi

BOX_STATUS=$(${PODMAN_MACHINE} status ${BOX_NAME})

BOX_DATA_DIR_EXISTS=$(${PODMAN_MACHINE} ssh ${BOX_NAME} "[ -d ${BOX_DATA_DIR} ]")
if [ $? ]; then
  ${PODMAN_MACHINE} ssh ${BOX_NAME} "rm ${BOX_DATA_DIR} -rf"
fi

${PODMAN_MACHINE} scp -r -q "../docs/" "${BOX_NAME}:${BOX_DATA_DIR}/"
${PODMAN_MACHINE} ssh ${BOX_NAME} "mkdir -p ${BOX_DATA_DIR}/_site; \
                        mkdir -p ${BOX_DATA_DIR}/.jekyll-cache;"
${PODMAN_MACHINE} ssh ${BOX_NAME} "chcon -R -t svirt_sandbox_file_t ${BOX_DATA_DIR}"

eval $(${PODMAN_MACHINE} env ${BOX_NAME} --varlink)

POD_EXISTS=$(${PODMAN} ps -a --format {{.Names}} | grep "^${BOX_POD_NAME}")
if [ $? -eq 0 ]; then
    echo "Delete pod ${BOX_POD_NAME}"
    ${PODMAN} stop ${BOX_POD_NAME}
    ${PODMAN} rm ${BOX_POD_NAME}
fi

echo "Run pod ${BOX_POD_NAME}"
${PODMAN} run -d \
              -p 4000:4000 \
              --volume="${BOX_DATA_DIR}:/srv/jekyll" \
              --name ${BOX_POD_NAME} \
              jekyll/jekyll:3.8 jekyll serve --incremental --trace

echo ""

echo "eval \$(${PODMAN_MACHINE} env ${BOX_NAME} --varlink)"

echo ""

echo "Access to the app: http://$(${PODMAN_MACHINE} ip ${BOX_NAME}):4000"
