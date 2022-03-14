#!/bin/sh

################################################################################
#
# Licensed Materials - Property of IBM
#
# "Restricted Materials of IBM"
#
# (C) COPYRIGHT IBM Corp. 2018 All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
################################################################################

#Global Static variables
VALUE_INT_YES=0
VALUE_INT_NO=1

CPD_RELEASE_CURRENT="4.0.6"
CPD_RELEASE="${CPD_RELEASE_CURRENT}"
DV_RELEASE="${CPD_RELEASE}"
DV_CUSTOM_RELEASE=""

isIAMEnabled="false"

# cpd-operators that hosts all cp4d operators including ibmcpd
# $SERVICE_INSTANCE_NAMESPACE that hosts cp4d pods
ZEN_OPERATORS_NAMESPACE="${ZEN_OPERATORS_NAMESPACE}"
SERVICE_INSTANCE_NAMESPACE="${SERVICE_INSTANCE_NAMESPACE}"

CP4D_WEB_URL="ibm-nginx-svc"
CP4D_WEB_URL_USERNAME="${CP4D_WEB_URL_USERNAME}"
CP4D_WEB_URL_PASSWORD="${CP4D_WEB_URL_PASSWORD}"

IAMINTEGRATION="false"

#Deployment/Provisioning parameters
PROVISION_VIA_CR=${VALUE_INT_NO}
IS_DV=${VALUE_INT_NO}

#DV specific paramters defaults  - can be overridden by user parms
MEMORY_REQUEST_SIZE="${MEMORY_REQUEST_SIZE}"
CPU_REQUEST_SIZE="${CPU_REQUEST_SIZE}"
PERSISTENCE_STORAGE_CLASS="${PERSISTENCE_STORAGE_CLASS}"
PERSISTENCE_STORAGE_SIZE="${PERSISTENCE_STORAGE_SIZE}"
CACHING_STORAGE_CLASS="${CACHING_STORAGE_CLASS}"
CACHING_STORAGE_SIZE="${CACHING_STORAGE_SIZE}"
WORKER_STORAGE_CLASS="${WORKER_STORAGE_CLASS}"
WORKER_STORAGE_SIZE="${WORKER_STORAGE_SIZE}"
DV_INSTALL_JSON_FILE_PATH="newdv.json"
MNTDIR="/scripts"
CMDDIR="/temp"

Usage() {
    cat <<EOF
DETAILED OPTIONS HELP

 #General Install Options
   --service-instance-namespace
   Service instance namespace. "liteproject" by default.
   --cpd-release
   the release of CPD that determines which branch of cpd-case repo we download CASE bundle tar balls

 #General Access Parameters
   --cp4d-web-username
   Username for cp4d web account, defaults to openshift username
   --cp4d-web-password
   Password for cp4d web account, defaults to openshift password

 # DV provisioning Parameters
   --memory-request-size
   Requested memory size. Use "8Gi" by default.
   --cpu-request-size
   Requested CPU size. Use "4" by default.
   --persistence-storage-class
   Persistence storage class. Use "nfs-client" by default.
   --persistence-storage-size
   Persistence storage size. Use "100Gi" by default.
   --caching-storage-class
   Caching storage class. Use "nfs-client" by default.
   --caching-storage-size
   Caching storage size. Use "100Gi" by default.
   --worker-storage-class
   Worker storage class. Use "nfs-client" by default.
   --worker-storage-size
   Worker storage size. Use "100Gi" by default.

EOF
}

echo "done"