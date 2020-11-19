#!/bin/bash

set -euo pipefail 


install() {
  kubectl delete po --ignore-not-found=true fleetcommand-agent-install

  kubectl create secret \
    docker-registry \
    -o yaml --dry-run \
    --docker-server=quay.io \
    --docker-username="${QUAY_USERNAME}" \
    --docker-password="${QUAY_PASSWORD}" \
    --docker-email=. domino-docker-repos | kubectl apply -f -

  kubectl create configmap \
    fleetcommand-agent-config \
    -o yaml --dry-run \
    --from-file="$(pwd)"/domino/domino.yml | kubectl apply -f -

  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: ServiceAccount
  metadata:
    name: admin
  ---
  apiVersion: rbac.authorization.k8s.io/v1
  kind: ClusterRoleBinding
  metadata:
    name: admin-default
  roleRef:
    apiGroup: rbac.authorization.k8s.io
    kind: ClusterRole
    name: cluster-admin
  subjects:
  - kind: ServiceAccount
    name: admin
    namespace: default
  ---
  apiVersion: v1
  kind: Pod
  metadata:
    name: fleetcommand-agent-install
  spec:
    serviceAccountName: admin
    imagePullSecrets:
      - name: domino-quay-repos
    restartPolicy: Never
    containers:
    - name: fleetcommand-agent
      image: quay.io/domino/fleetcommand-agent:${FLEETCOMMAND_AGENT_VERSION}
      args: ["run", "-f", "/app/install/domino.yml","-s", "${SERVICE}" "-v"]
      imagePullPolicy: Always
      volumeMounts:
      - name: install-config
        mountPath: /app/install/
    volumes:
    - name: install-config
      configMap:
        name: fleetcommand-agent-config
EOF

  set +e
  while true; do
    sleep 5
    if kubectl logs -f fleetcommand-agent-install; then
      break
    fi
  done
}

help() {
   echo
   echo "Syntax: ./service.sh -v FLEETCOMMAND_AGENT_VERSION -u QUAY_USERNAME -p QUAY_PASSWORD -s SERVICE"
   echo "options:"
   echo "-h     [optional] prints this help message."
   echo "-v     [required] version of quay.io/domino/fleetcommand_agent container."
   echo "-u     [required] username for https://quay.io "
   echo "-p     [required] password for https://quay.io "
   echo "-s     [required] domino service name to update."
   echo
}

FLAGCOUNT=0
while getopts v:u:p:s:h flag; do
    case "${flag}" in
      v)
        FLEETCOMMAND_AGENT_VERSION=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      u)
        QUAY_USERNAME=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      p)
        QUAY_PASSWORD=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      s)
        SERVICE=${OPTARG}
        FLAGCOUNT=$((FLAGCOUNT+1))
        ;;
      h)
        help
        exit 
        ;;
      *)
        help
        exit 1
        ;;
    esac
done

if [ $FLAGCOUNT -ne 4 ] ; then
    echo "Missing required argument."
    help
    exit 1
else 
    install
    exit 0
fi
