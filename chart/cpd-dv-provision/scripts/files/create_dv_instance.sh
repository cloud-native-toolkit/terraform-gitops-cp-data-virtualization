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

echo "done"