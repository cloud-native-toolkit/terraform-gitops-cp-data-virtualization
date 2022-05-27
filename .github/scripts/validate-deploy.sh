#!/usr/bin/env bash

GIT_REPO=$(cat git_repo)
GIT_TOKEN=$(cat git_token)

export KUBECONFIG=$(cat .kubeconfig)
NAMESPACE=$(jq -r '.cpd_namespace // "gitops-cp4d-instance"' gitops-output.json)
CPD_NAMESPACE=$(jq -r '.cpd_namespace // "cpd_namespace"' gitops-output.json)
COMPONENT_NAME=$(jq -r '.name // "my-module"' gitops-output.json)
BRANCH=$(jq -r '.branch // "main"' gitops-output.json)
SERVER_NAME=$(jq -r '.server_name // "default"' gitops-output.json)
LAYER=$(jq -r '.layer_dir // "2-services"' gitops-output.json)
TYPE=$(jq -r '.type // "base"' gitops-output.json)

mkdir -p .testrepo

git clone https://${GIT_TOKEN}@${GIT_REPO} .testrepo

cd .testrepo || exit 1

find . -name "*"

if [[ ! -f "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml" ]]; then
  echo "ArgoCD config missing - argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
  exit 1
fi

echo "Printing argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"
cat "argocd/${LAYER}/cluster/${SERVER_NAME}/${TYPE}/${NAMESPACE}-${COMPONENT_NAME}.yaml"

if [[ ! -f "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml" ]]; then
  echo "Application values not found - payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
  exit 1
fi

echo "Printing payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"
cat "payload/${LAYER}/namespace/${NAMESPACE}/${COMPONENT_NAME}/values.yaml"

count=0
until kubectl get namespace "${NAMESPACE}" 1> /dev/null 2> /dev/null || [[ $count -eq 20 ]]; do
  echo "Waiting for namespace: ${NAMESPACE}"
  count=$((count + 1))
  sleep 15
done

if [[ $count -eq 20 ]]; then
  echo "Timed out waiting for namespace: ${NAMESPACE}"
  exit 1
else
  echo "Found namespace: ${NAMESPACE}. Sleeping for 30 seconds to wait for everything to settle down"
  sleep 30
fi

while [ true ]; do
  status=$(oc -n ${CPD_NAMESPACE} get dvservice --no-headers | awk '{print $2}')
  echo "DV Service status is "${status}""
  if [ $status == "True" ]; then
    echo "DV Service status is True"
    sleep 60
    break
  fi
done

echo "DV Readiness Check"

dvenginePod=$(oc get pod -n $CPD_NAMESPACE --no-headers=true -l component=db2dv,name=dashmpp-head-0,role=db,type=engine | awk '{print $1}')
echo "DV engine head pod is $dvenginePod"

#Wait until the DV service is  ready
dvNotReady=1
iter=0
maxIter=120 #DV takes longer than BigSQL to become ready
while [ true ]; do
    oc logs -n $CPD_NAMESPACE $dvenginePod | grep "db2uctl markers get QP_START_PERFORMED" >/dev/null
    echo "dvNotReady "$dvNotReady""
    dvNotReady=$?
    if [ $dvNotReady -eq 0 ]; then
        break
    else
        echo "Waiting for the DV service to be ready. Recheck in 30 seconds"
        let iter=iter+1
        if [ $iter == $maxIter ]; then
          exit 1
        fi
        sleep 30
    fi
done

cd ..
rm -rf .testrepo