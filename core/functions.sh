#!/usr/bin/env bash

# Created by tomakoz[at]gmail[dot]com
# Licensed by GNU/GPL v3

function setLog() {
  if [[ "${LogDir}" == "" ]]; then
    LogDir="${SCRIPT_PATH}/log"
  fi
  LogFilePrefix=`basename ${0} .sh`
  LogFileDate=`date +"%Y-%m-%d"`
  LogFile="${LogDir}/${LogFilePrefix}_${LogFileDate}.log"
  if [ ! -d "${LogDir}" ]; then
    MakeDir "${LogDir}"
  fi
  echo "${LogFile}"
}

function setTmp() {
  if [[ "${TmpDir}" == "" ]]; then
    TmpDir="${SCRIPT_PATH}/tmp"
  fi
  _tmp="${TmpDir}/$$.tmp"
  if [ -f "$_tmp" ]; then
    tmp=`basename "${_tmp}" .tmp`
    _tmp="${TmpDir}/${tmp}.$$.tmp"
  fi
  echo $_tmp
}

function ClearTmp() {
  if [ -f "${_tmp}" ]; then
    TmpDir=`dirname ${_tmp}`
    rm "${TmpDir}/$$."*
  fi
}

function MakeDir() {
  dir="${1}"
  if [ ! -d "${dir}" ]; then
    mkdir -p "${dir}" && EchoSuccessLog "mkdir ${dir}" || EchoErrorLog "mkdir ${dir}"
  fi
}


function isTerm() {
  cols=$(tput cols)
  if [[ "" != "${cols}" ]]; then
    return TRUE
  else
    return FALSE
  fi
}

function Echo() {
  if [ ! isTerm  ]; then
    echo "${1}"
  else
    echo -e "\\033[0;33m${1}\\033[0m"
  fi
}

function EchoError() {
  if [ ! isTerm ]; then
    echo "${1}"
  else
    echo -e "\\033[0;31m${1}\\033[0m"
  fi
}

function EchoSuccess() {
  if [ ! isTerm ]; then
    echo "${1}"
  else
    echo -e "\\033[0;32m${1}\\033[0m"
  fi
}

function EchoMsg() {
  if [ ! isTerm ]; then
    echo "${1}"
  else
    echo -e "\\033[1;33m${1}\\033[0m"
  fi
}

function EchoCopy() {
  if [ ! isTerm ]; then
    echo "${1}"
  else
    echo -e "\\033[1;36m${1}\\033[0m"
  fi
}

function EchoColor() {
  if [ ! isTerm ]; then
    echo "${1}"
  else
    echo -e "\\033[${2}m${1}\\033[0m"
  fi
}


function EchoLog() {
    LogMsg="[`date +"%d.%m.%Y %X"`]: [INFO] ${0} - ${1}"
    EchoMsg "${LogMsg}" && echo "${LogMsg}" >> "${LogFile}"
}
function EchoSuccessLog() {
  LogMsg="[`date +"%d.%m.%Y %X"`]: [OK] ${0} - ${1}"
  EchoSuccess "${LogMsg}" && echo "$LogMsg" >> "${LogFile}"
}
function EchoErrorLog() {
   LogMsg="[`date +"%d.%m.%Y %X"`]: [ERROR] ${0} - ${1}"
   EchoError "${LogMsg}" && echo "$LogMsg" >> "${LogFile}"
}

function EchoCopyLog() {
  LogMsg="[`date +"%d.%m.%Y %X"`]: [OK] $(basename ${0}) - ${LogKey} - ${1}"
  #logger -p local7.info "$(basename ${0}) - ${LogKey} - ${1}"
  EchoCopy "${LogMsg}" && echo "$LogMsg" >> "${LogFile}"
}

function Sync() {
  Date=`date +"%Y-%m-%d %H:%M:%S"`
  EchoSuccessLog "SYNC BEGIN ${1} => ${2}"
  #echo -e "\\033[029m${Date}: SYNC BEGIN ${1} => ${2} \\033[0m\n"
  if [ -d "${1}" ]; then
    SrcDir=${1}
  else
    echo -e  "\\033[031mERROR: Empty or wrong source directory ${1}\\033[0m\n"
    exit;
  fi
  if [ -d "${2}" ]; then
    DstDir=${2}
  else
    echo -e "\\033[031mERROR: Empty or wrong destination directory ${2}\\033[0m\n"
    exit
  fi

  DstDir=${2}
  RSYNC=$(which rsync)
  $RSYNC -Hauvz --progress "${SrcDir}" "${DstDir}" && EchoSuccessLog "SYNC END ${1} => ${2}" || EchoErrorLog "SYNC END ${1} => ${2}\n"
  #Date=`date +"%Y-%m-%d %H:%M:%S"`
  #echo -e "\\033[029m${Date}: SYNC END ${1} => ${2} \\033[0m\n"

}

function sshSync() {
  echo "sshSync"
}

function getFormat() {
  ProjectConfig="${1}"
  format=`cat "${ProjectConfig}" | sed -e 's/[{}]/''/g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | grep '"size":' | sed 's/:/ /1' | awk -F" " '{ print $2 }' | tr -d '"'`
  echo "${format}"
}


function OrdersList() {
  if [ ! -f "${1}" ]; then
    echo "ERROR OrdersList"
    exit
  fi
  list=${1}
  ids=""
  i=0
  while read id
  do
    if [ ${i} = 0 ]; then
      ids="${id}"
    else
      ids="${ids},${id}"
    fi
    ((i++))
  done < $list

  echo "${ids}"
}

function OrdersWitchAutoCorrected() {
#  FILE='./ascp_orders.lst'
  FILE="${1}"
  OUT=""
  while read ORDER
  do
    isAutoCorrect=$(echo ${ORDER} | awk 'BEGIN { FS="|" } { print $10 }')
    numer=$(echo ${ORDER} | awk 'BEGIN { FS="|" } { print $1 }')
    if [ "${isAutoCorrect}" = 1 ]; then
      OUT="${OUT}\n${numer}"
    fi
  done < $FILE
  echo -e "${OUT}"
}

function ToDay() {
  echo `date +"%Y-%m-%d"`
}

function Now() {
  echo `date +"%Y-%m-%d %H:%I:%S"`
}

function NowUnix() {
  echo `date +"%s"`
}

function Aeval() {
  CMD="${1}"
  FORCE="${2}"

  if [[ "${DEBUG}" == "DEBUG" && "${FORCE}" == "" ]]; then
    echo "${CMD}"
  else
    if [ $(echo "${CMD}" | egrep '^(cp|mkdir|mv|rm)' | wc -l) == 1 ]; then
        eval "${CMD}" && EchoCopyLog "${CMD}" || EchoErrorLog "${CMD}"
    else
        eval "${CMD}" && EchoSuccessLog "${CMD}" || EchoErrorLog "${CMD}"
    fi
  fi
#   echo "${CMD}"
}

