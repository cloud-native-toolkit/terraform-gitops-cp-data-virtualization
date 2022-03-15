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

#Any logic that requires modification of parms based on conditions here
init_parameters() {

    if [ "$DV_CUSTOM_RELEASE" != "" ]; then
        DV_RELEASE=${DV_CUSTOM_RELEASE}
    else
        if [ "${CPD_RELEASE}" = "4.0.4" ]; then
            DV_RELEASE="4.0.3"
        else
            DV_RELEASE=${CPD_RELEASE}
        fi
    fi

    IS_DV=${VALUE_INT_YES}

}

#prints the parameter values that the install will use
print_install_parameters() {

    log_info "General parameters: "
    log_info "Zen Namespace: ${SERVICE_INSTANCE_NAMESPACE}"
    log_info "Zen Operators Namespace: ${ZEN_OPERATORS_NAMESPACE}"
    log_info "CP4D Custom User: ${CP4D_WEB_URL_USERNAME}"
    log_info "CP4D iamIntegration is set to ${IAMINTEGRATION}"
    echo

    echo
    log_info "Version/Tag parameters : "
    oc get ibmcpd ibmcpd-cr -n ${SERVICE_INSTANCE_NAMESPACE} -o yaml | grep ' zenOperatorBuildNumber: '

    log_info "CPD Release Version  : ${CPD_RELEASE}"
    log_info "DV Release Version  : ${DV_RELEASE}"

    echo
    #print dv specific parameters

    log_info "Number of worker pods: ${NUMBER_OF_WORKERS}"
    log_info "Requested memory size: ${MEMORY_REQUEST_SIZE}"
    log_info "Requested CPU size: ${CPU_REQUEST_SIZE}"
    log_info "Persistence Storage Class: ${PERSISTENCE_STORAGE_CLASS}"
    log_info "Persistence Storage Size: ${PERSISTENCE_STORAGE_SIZE}"
    log_info "Caching Storage Class: ${CACHING_STORAGE_CLASS}"
    log_info "Caching Storage Size: ${CACHING_STORAGE_SIZE}"
    log_info "Worker Storage Class: ${WORKER_STORAGE_CLASS}"
    log_info "Worker Storage Size: ${WORKER_STORAGE_SIZE}"

    echo
} #end of print_install_parameters

#Helper Functions
exists() {
    if command -v $1 &>/dev/null; then
        return
    fi

    if [ -f $1 ]; then
        return
    fi
    false
}

get_dv_version() {
    cpd_release=${DV_RELEASE}
    if [[ "$cpd_release" == "4.0.0" ]]; then
        echo '1.7.0'
    elif [[ "$cpd_release" == "4.0.1" ]]; then
        echo '1.7.1'
    elif [[ "$cpd_release" == "4.0.2" ]]; then
        echo '1.7.2'
    elif [[ "$cpd_release" == "4.0.3" ]]; then
        echo '1.7.3'
    elif [[ "$cpd_release" == "4.0.4" ]]; then
        echo '1.7.3'
    elif [[ "$cpd_release" == "4.0.5" ]]; then
        echo '1.7.5'
    else
        echo '1.7.3'
    fi
}

get_dv_service_version() {
    local dv_service_version=$(oc -n ${SERVICE_INSTANCE_NAMESPACE} get dvservice dv-service -o jsonpath="{.spec.version}")
    echo $dv_service_version
}

#create the dv provisioner role
ibm_dv_provisioner_role() {

    log_info "Create DV provisioner role"
    oc create -f /scripts/ibm_dv_provisioner_role.yaml 2>&1

} #end of ibm_dv_provisioner_role

#create the ibm dv provisioner rolebinding
ibm_dv_provisioner_rolebinding() {

    log_info "Create DV provisioner role binding"
    oc create -f /scripts/ibm_dv_provisioner_rolebinding.yaml 2>&1

} #end of ibm_dv_provisioner_rolebinding

#create the jwt token:https://cloud.ibm.com/apidocs/cloud-pak-data
#to decode the jwt token use https://www.base64decode.org/
create_jwt_token() {

    COOKIE_FILE="${SERVICE_INSTANCE_NAMESPACE}.bigsql.cookie"
    COOKIE_FILE_PATH="${CMDDIR}/${COOKIE_FILE}"
    log_info "The cookie file path is ${COOKIE_FILE_PATH}"
    log_info "The CP4D WEB URL is ${CP4D_WEB_URL}"

    #Delete existing cookie file
    log_info "Delete existing cookie file"
    rm -f ${COOKIE_FILE}

    isIAMEnabled=$(oc get ibmcpd ibmcpd-cr -n ${SERVICE_INSTANCE_NAMESPACE} -o jsonpath={.spec.iamIntegration})

    if [[ $isIAMEnabled == "true" ]]; then
        platform_auth_namespace="ibm-common-services"
        cp4dPassword=$(oc -n $platform_auth_namespace get secret platform-auth-idp-credentials -o jsonpath='{.data.admin_password}' | base64 --decode)
        log_info ""
        log_info "IAM is enabled, using admin password: $cp4dPassword"
        log_info ""
        #Get I am Access token
        route1=$(oc get route --no-headers --namespace $platform_auth_namespace | grep cp-console | awk '{print $2}')
        PRETOKEN1=$(curl -sSk --request POST --url https://${route1}/idprovider/v1/auth/identitytoken -d "grant_type=password&username=admin&password=${cp4dPassword}&scope=openid")
        pretoken=$(echo $PRETOKEN1 | tr "," "\n" | grep access_token | cut -c18- | rev | cut -c2- | rev)
        #Use above token to genearte zen token
        TOKEN=$(curl -sSk --request GET --url https://${CP4D_WEB_URL}/v1/preauth/validateAuth --header "username: admin" --header "iam-token: $pretoken")
        token=$(echo $TOKEN | tr "," "\n" | grep accessToken | tail -n1 | cut -c16- | rev | cut -c2- | rev)
    else
        log_info "IAM is disabled, using admin password: password"
        payload="{\"username\":\"${CP4D_WEB_URL_USERNAME}\",\"password\":\"${CP4D_WEB_URL_PASSWORD}\"}"
        log_info "The JWT token paylod is ${payload}"

        log_info "Generating the JWT token"
        #this generates a token;
        curl -v -c ${COOKIE_FILE_PATH} "https://${CP4D_WEB_URL}/v1/preauth/signin?context=${SERVICE_INSTANCE_NAMESPACE}" -H "Origin: https://${CP4D_WEB_URL}" -H "Accept-Encoding: gzip, deflate, br" -H "Accept-Language: en-US,en;q=0.9" -H "User-Agent: Mozilla/5.0" -H "Content-Type: application/json;charset=UTF-8" -H "Accept: application/json, text/plain, */*" -H "Referer: https://${CP4D_WEB_URL}/${SERVICE_INSTANCE_NAMESPACE}/" -H "Cookie: __preloginurl__=/${SERVICE_INSTANCE_NAMESPACE}/" -H "Connection: keep-alive" -d "${payload}" --compressed --insecure

        log_info "Wait for 10 sec to get the JWT token"
        sleep 10s

        #store the token
        token=$(awk '{for (I=1;I<=NF;I++) if ($I == "ibm-private-cloud-session") {print $(I+1)};}' ${COOKIE_FILE_PATH})

    fi

} #end of create_jwt_token

#check dv head pod status
#Check using new bigsql CRD
check_dv_head_pod_status() {

    log_info "Waiting for DV head pod to start running"

    #Wait until the head pod is in 1/1 state & running
    opNotReady=1
    iter=0
    maxIter=60
    while [ $opNotReady -eq 1 ] && [ $iter -le $maxIter ]; do
        [ $(oc get pod -n $SERVICE_INSTANCE_NAMESPACE --no-headers=true -l component=db2dv,name=dashmpp-head-0,role=db,type=engine | awk '{print $2}' | awk -F'/' ' BEGIN {count = 0}  $1 == $2 {count++ } END {print count}') -eq 1 ] && break
        oc get pod -n $SERVICE_INSTANCE_NAMESPACE --no-headers=true -l component=db2dv,name=dashmpp-head-0,role=db,type=engine
        [ $(oc get pod -n $SERVICE_INSTANCE_NAMESPACE | grep c-dv | grep Error | wc -l) -gt 0 ] && {
            log_fatal "At least 1 DV  Pod is in error state, failing the provisioning now."
            exit 1
        }
        log_info "Waiting for DV Head Pod to become ready.. ($iter / $maxIter)"
        let iter=iter+1
        sleep 20
    done

    [ $iter -eq $maxIter ] && {
        log_warning "Maximum iteration has been reached and DV Head Pod still not running and 1/1, exit"
        exit 1
    }

    log_info "DV head pod ready & running"

}

#check dv worker pod status
#Check using new bigsql CRD
check_dv_worker_pod_status() {

    log_info "Waiting for DV worker pod to start running"

    #Wait until the worker pod is in 1/1 state & running
    opNotReady=1
    iter=0
    maxIter=60
    while [ $opNotReady -eq 1 ] && [ $iter -le $maxIter ]; do
        [ $(oc get pod -n $SERVICE_INSTANCE_NAMESPACE --no-headers=true -l component=db2dv,name\!=dashmpp-head-0,role=db,type=engine | awk '{print $2}' | awk -F'/' ' BEGIN {count = 0}  $1 == $2 {count++ } END {print count}') -eq ${NUMBER_OF_WORKERS} ] && break
        oc get pod -n $SERVICE_INSTANCE_NAMESPACE --no-headers=true -l component=db2dv,name!=dashmpp-head-0,role=db,type=engine
        [ $(oc get pod -n $SERVICE_INSTANCE_NAMESPACE | grep c-dv | grep Error | wc -l) -gt 0 ] && {
            log_fatal "At least 1 DV pod is in error state, failing the provisioning now."
            exit 1
        }
        log_info "Waiting for required DV Worker Pods(${NUMBER_OF_WORKERS}) to become ready.. ($iter / $maxIter)"
        let iter=iter+1
        sleep 20
    done

    [ $iter -eq $maxIter ] && {
        log_warning "Maximum iteration has been reached and DV Workers Pods still not running and 1/1, exit"
        exit 1
    }

    log_info "DV worker pod(s) ready & running"

}

#check dv is ready to use
check_dv_ready_state() {

    log_info "DV Readiness Check"

    dvenginePod=$(oc get pod -n $SERVICE_INSTANCE_NAMESPACE --no-headers=true -l component=db2dv,name=dashmpp-head-0,role=db,type=engine | awk '{print $1}')
    log_info "DV engine head pod is $dvenginePod"

    #Wait until the DV service is  ready
    dvNotReady=1
    iter=0
    maxIter=120 #DV takes longer than BigSQL to become ready
    while [ $dvNotReady -eq 1 ] && [ $iter -le $maxIter ]; do
        oc logs -n $SERVICE_INSTANCE_NAMESPACE $dvenginePod | grep "db2uctl markers get QP_START_PERFORMED" >/dev/null
        dvNotReady=$?
        if [ $dvNotReady -eq 0 ]; then
            break
        else
            log_info "Waiting for the DV service to be ready. Recheck in 30 seconds"
            let iter=iter+1
            sleep 30
        fi
    done

    if [ $dvNotReady -eq 1 ]; then
        log_info "The container logs are:"
        oc logs -n $SERVICE_INSTANCE_NAMESPACE $bigsqlenginePod | tail -300
        log_error "DV service is still not ready after waiting for $maxIter intervals of 30 seconds"
        exit 1
    else
        echo "[INFO] DV service is ready... [current check is phrase -> db2uctl markers get SETUP_COMPLETE]"
    fi
}

#We do not use this by default because DV validation script waits and checks if DV pods are running
check_dv_provision() {

    log_info "Check DV provisioning, this operation may take some time.. "
    #wait for head pod to run
    check_dv_head_pod_status
    check_dv_worker_pod_status
    check_dv_ready_state

    echo -e "\e[1;42m DV  PROVISIONING COMPLETED  \e[0m"

    log_info "OpenShift version:"
    oc version
    log_info "cloudctl version:"
    ./${CLOUDCTLEXEC} version
    log_info "lite version"
    oc get zenservice lite-cr -n $SERVICE_INSTANCE_NAMESPACE -o yaml | grep ' zenOperatorBuildNumber: '

    #v3 api to fetch instances
    log_info "Listing all provisioned cp4d instances"
    create_jwt_token
    curl -k -v -H "Authorization: Bearer ${token}" -X GET https://${CP4D_WEB_URL}/zen-data/v3/service_instances

} #End of get_installed_versions

get_timestamp() {
    local pretty_print="${1:-$VALUE_INT_YES}"
    if [ $pretty_print -eq $VALUE_INT_YES ]; then
        #Default to pretty print for logging
        echo "["$(date -u +"%H:%M:%S,%3N %Z")"]"
    else
        #"2021040319h45m09s" style to be used in file names
        echo $(date "+%Y%m%d%Hh%Mm%Ss")
    fi
}

trim_spaces() {
    local ENTRIES="$@"
    result=$(echo "$ENTRIES" | sed -e 's/^ *//' -e 's/ *$//')
    echo $result
}

#Provision DV via Zen core REST API
provision_dv() {
    local dv_instance_version=$(get_dv_version) #default to 1.7.1, once we switch to CP4D River 4.0.2, default will move up to 1.7.2
    local dv_service_version=$(get_dv_service_version)

    if [ -z "${dv_service_version}" ]; then
        log_warning "Unable to get DV service version. Use default DV instance version instead ${dv_instance_version}"
    else
        if [ "${dv_service_version}" != "${dv_instance_version}" ]; then
            log_warning "DV service version ${dv_service_version} is different from expected DV instance version ${dv_instance_version}"
            log_warning "Provision DV instance version using DV service version ${dv_service_version} instead"
            dv_instance_version=${dv_service_version}
        fi
    fi

    log_info "Provision DV instance version ${dv_instance_version}"

    #check DV and db2u crds
    oc get crd | grep -i bigsqls.db2u.databases.ibm.com
    if [[ $? -ne 0 ]]; then
        log_error "DV/db2u CRD bigsqls.db2u.databases.ibm.com missing"
        exit 1
    fi

    oc get crd | grep -i db2uclusters.db2u.databases.ibm.com
    if [[ $? -ne 0 ]]; then
        log_error "DV/db2u CRD db2ucluster.db2u.databases.ibm.com missing"
        exit 1
    fi

    log_info "Wait for stabilization"
    sleep 120s

    local current_timestamp=$(get_timestamp $VALUE_INT_NO) #print a "ugly" timestamp like "2021040319h45m09s"
    log_info "Current Timestamp: $current_timestamp"

    #create the jwt token:https://cloud.ibm.com/apidocs/cloud-pak-data
    create_jwt_token
    log_info "The jwt token is ${token}"
    sleep 10s

    if [ "${token}" == "" ]; then
        log_fatal "JWT token is not generated "
        log_fatal ""
        exit 1
    fi

    NUMBER_OF_WORKERS=$(trim_spaces "${NUMBER_OF_WORKERS}")

    MEMORY_REQUEST_SIZE=$(trim_spaces "${MEMORY_REQUEST_SIZE}")
    CPU_REQUEST_SIZE=$(trim_spaces "${CPU_REQUEST_SIZE}")

    PERSISTENCE_STORAGE_CLASS=$(trim_spaces "${PERSISTENCE_STORAGE_CLASS}")
    PERSISTENCE_STORAGE_SIZE=$(trim_spaces "${PERSISTENCE_STORAGE_SIZE}")

    WORKER_STORAGE_CLASS=$(trim_spaces "${WORKER_STORAGE_CLASS}")
    WORKER_STORAGE_SIZE=$(trim_spaces "${WORKER_STORAGE_SIZE}")

    CACHING_STORAGE_CLASS=$(trim_spaces "${CACHING_STORAGE_CLASS}")
    CACHING_STORAGE_SIZE=$(trim_spaces "${CACHING_STORAGE_SIZE}")

    log_info "Update DV provisioning parameters"

    local current_json="$(echo $DV_INSTALL_JSON_FILE_PATH | sed "s/.json//").$current_timestamp.json"
    log_info "Provision DV via Zen core API with payload $current_json"
    cp "${MNTDIR}/${DV_INSTALL_JSON_FILE_PATH}" "${CMDDIR}/${current_json}"

    log_info "Update DV instance version"
    sed -i "s/\"addon_version\": \"1.7.0\"/\"addon_version\": \"${dv_instance_version}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV service instance namespace"
    sed -i "s/\"namespace\": \"zen\"/\"namespace\": \"${SERVICE_INSTANCE_NAMESPACE}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV requested memory size"
    sed -i "s/\"resources.dv.requests.memory\": \"8Gi\"/\"resources.dv.requests.memory\": \"${MEMORY_REQUEST_SIZE}\"/g" "${CMDDIR}/${current_json}"
    sed -i "s/\"memory\": \"8\"/\"memory\": \"$(echo ${MEMORY_REQUEST_SIZE} | sed "s/Gi//g")\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV requested cpu size"
    sed -i "s/\"resources.dv.requests.cpu\": \"4\"/\"resources.dv.requests.cpu\": \"${CPU_REQUEST_SIZE}\"/g" "${CMDDIR}/${current_json}"
    sed -i "s/\"cpu\": \"4\"/\"cpu\": \"${CPU_REQUEST_SIZE}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV persistence storage class"
    sed -i "s/\"persistence.storageClass\": \"nfs-client\"/\"persistence.storageClass\": \"${PERSISTENCE_STORAGE_CLASS}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV persistence storage size"
    sed -i "s/\"persistence.size\": \"100Gi\"/\"persistence.size\": \"${PERSISTENCE_STORAGE_SIZE}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV caching storage class"
    sed -i "s/\"persistence.cachingpv.storageClass\": \"nfs-client\"/\"persistence.cachingpv.storageClass\": \"${CACHING_STORAGE_CLASS}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV caching storage size"
    sed -i "s/\"persistence.cachingpv.size\": \"100Gi\"/\"persistence.cachingpv.size\": \"${CACHING_STORAGE_SIZE}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV worker storage class"
    sed -i "s/\"persistence.workerpv.storageClass\": \"nfs-client\"/\"persistence.workerpv.storageClass\": \"${WORKER_STORAGE_CLASS}\"/g" "${CMDDIR}/${current_json}"

    log_info "Update DV worker storage size"
    sed -i "s/\"persistence.workerpv.size\": \"100Gi\"/\"persistence.workerpv.size\": \"${WORKER_STORAGE_SIZE}\"/g" "${CMDDIR}/${current_json}"

}

echo "done"
