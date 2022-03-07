#!/usr/bin/env bash

SCRIPT_DIR=$(cd $(dirname "$0"); pwd -P)
SUPPORT_DIR=$(cd "${SCRIPT_DIR}/../support"; pwd -P)
TEMPLATE_DIR=$(cd "${SCRIPT_DIR}/../templates"; pwd -P)

cat "${SUPPORT_DIR}/configmap.snippet.yaml" > "${TEMPLATE_DIR}/configmap.yaml"

oc create configmap dv-provision-cm \
  --from-file=${SCRIPT_DIR}/create_dv_instance.sh \
  --from-file=${SCRIPT_DIR}/=ibm_dv_provisioner_role.yaml \
  --from-file=${SCRIPT_DIR}/ibm_dv_provisioner_rolebinding.yaml \
  --from-file=${SCRIPT_DIR}/newdv.json \
  --dry-run=client \
  -o yaml | \
yq eval 'del(.apiVersion) | del(.kind) | del(.metadata)' - >> "${TEMPLATE_DIR}/configmap.yaml"
