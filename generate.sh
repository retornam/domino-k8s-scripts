#!/bin/bash

set -euo pipefail

CURRENTDATE=$(date +"%Y-%m-%d")
NIXTIME=$(date +"%s")
DOCKER_REGISTRY=""
VERSION=""

generate() {
	docker run --rm  \
	       -v "$(pwd)"/domino:/install quay.io/domino/fleetcommand-agent:"${VERSION}" \
	       init --file /install/domino-"${VERSION}"-"${CURRENTDATE}"-"${NIXTIME}".yml
}

generateCustom() {
  docker run --rm  \
         -v "$(pwd)"/domino:/install quay.io/domino/fleetcommand-agent:"${VERSION}" \
         init --file /install/domino-"${VERSION}"-"${CURRENTDATE}"-"${NIXTIME}".yml \
         -F --image-registry "${DOCKER_REGISTRY}"

}

help() {
   echo 
   echo "Syntax: ./generate.sh -v FLEETCOMMAND_AGENT_VERSION -r DOCKER_REGISTRY"
   echo "options:"
   echo "-h     [optional] prints this help message."
   echo "-v     [required] version of quay.io/domino/fleetcommand_agent container."
   echo "-r     [optional] path to custom docker registry"
   echo
}

FLAGCOUNT=0
while getopts v:r:h flag; do
    case "${flag}" in
      v)
        VERSION=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      h)
        help
        exit 0
        ;;
      r)
        DOCKER_REGISTRY=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      *)
        help
        exit 1
        ;;
    esac
done

if [ $FLAGCOUNT -eq 0 ] ; then
    echo "Missing required argument."
    help
    exit 1
elif [ "${FLAGCOUNT}" -eq 1 ] && [ "${DOCKER_REGISTRY}" == "" ]; then
   generate
elif [ "${FLAGCOUNT}" -eq 2 ] && { [ "${DOCKER_REGISTRY}" != "" ] && [ "${VERSION}" != "" ] ; } ; then
  generateCustom
fi

