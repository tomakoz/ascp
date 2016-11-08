#!/bin/bash


#===  FUNCTION  ================================================================
#          NAME:  check_device
#   DESCRIPTION:  checking if device exist in the masin
#    PARAMETERS:  device
#       RETURNS:  TAK/NIE
#===============================================================================


function check_device ()
{
    if [ -b "${1}" ]; then
        echo "1"
    else
        echo "0"
    fi
}    # ----------  end of function check_device  ----------


#===  FUNCTION  ================================================================
#          NAME:  get_uuid
#   DESCRIPTION:  geting UUID partition
#    PARAMETERS:  device
#       RETURNS:  string
#===============================================================================

function get_uuid ()
{
    device=$1
    if [[ $(check_device $device) != "1" ]] ; then
        return "0"
        exit
    fi
    UUID=$(blkid ${device} | sed "s/\\s/\\n/g" | egrep '^UUID' | awk -v FS="=" {'print $2;'} | tr -d '"')
    if [[ "${UUID}" != "" ]]; then
        echo "${UUID}"
    else
        echo ""
    fi
}    # ----------  end of function get_uuid  ----------


#===  FUNCTION  ================================================================
#          NAME:  get_label
#   DESCRIPTION:  geting label of partition
#    PARAMETERS:  device
#       RETURNS:  string
#===============================================================================


function get_label ()
{
    device=$1
    if [[ $(check_device $device) != "1" ]]; then
        return "0"
        exit
    fi

    LABEL=$(blkid ${device} | sed "s/\\s/\\n/g" | egrep '^LABEL' | awk -v FS="=" {'print $2;'} | tr -d '"')
    # if [[ "${LABEL}" == "" ]]; then
    #    echo -e "Inser label/name of mounting device" 
    #    read LABEL
    # fi
    echo "${LABEL}"
}    # ----------  end of function get_label  ----------


#===  FUNCTION  ================================================================
#          NAME:  get_fs_tyoe
#   DESCRIPTION:  geting file system type
#    PARAMETERS:  device
#       RETURNS:  
#===============================================================================


function get_fs_type()
{
    device=$1
    if [[ $(check_device $device) != "1" ]] ; then
        exit 127

    fi
    TYPE=$(blkid ${device} | sed "s/\\s/\\n/g" | egrep '^TYPE' | awk -v FS="=" {'print $2;'} | tr -d '"')
    echo "${TYPE}"
}    # ----------  end of function get_fs_type  ----------


function check_mount() {
  MountDest="${1}"
  is_mount=$(mount | grep "${MountDest}" | wc -l)
  if [[ "${is_mount}" == "1"  ]]; then
    echo "OK"
  else
    echo "NOK"
  fi
}

function check_mounts() {
  echo "${0}"
}

function remount() {
  MountDest="${1}"
  UMOUNT=$(which umount)
  MOUNT=$(which mount)

  if [[ "${1}" == ""  ]]; then
    return "0"
  else
    #$UMOUNT "${MountDest}"
    $MOUNT "${MountDest}"
    if [[ $(check_mount "${MountDest}") == "OK" ]]; then
      return "1"
    else
      #EchoErrorLog "Remount ${MountDest}"
      return "0"
    fi
  fi
}



function partition_list() {
    echo -n "\\033[0;33m TEST\\033[0m"
    
    #-------------------------------------------------------------------------------
    #   check if run as root
    #-------------------------------------------------------------------------------
    if [[ "${UID}" != "0" ]]; then
       echo -e "Run this script as root\n" 
       return 0
       exit
    fi


    #-------------------------------------------------------------------------------
    #   check if device exist
    #-------------------------------------------------------------------------------
    device="${1}"
     if [ ! -d "${device}" ] ; then
       echo -e "Device \\033[0;33m${device}\\033[0m not exist\n" 
       return 0
       exit
    fi

    _partitions=$(tempfile)
    echo "${_partitions}"
    fdisk -l "${device}" | egrep "^\/" > $_partitions
    if [ $(cat ${_partitions} | wc -l) -gt 0 ]; then
    cat "${_partitions}"
       rm "${_partitions}"
    else
        return "0"
    fi
}



#===  FUNCTION  ================================================================
#          NAME:  check_mount_path
#   DESCRIPTION:  function to checking mount path. Check existing directory,
#                 check existing in fstab
#                 check is alredy mount
#    PARAMETERS:  mount_path
#       RETURNS:  boolen
#===============================================================================\

function check_mount_path ()
{
    mount_path="${1}"
    if [[ "${mount_path}" == "" ]]; then
        # EchoError "Empty mount path"
        if [[ "$(echo $?)" == 0 ]]; then
            exit
        else
            echo "127"
        fi
    elif [[ $(check_mount "${mount_path}") == "OK" ]]; then
        # EchoError "Mount path is used"
        echo "123"
    elif [[ $(cat /etc/fstab | grep "${mount_path}" | wc -l) == 1 ]]; then
        echo "124"
    else
        echo "1"
    fi
}    # ----------  end of function check_mount_path  ----------



#===  FUNCTION  ================================================================
#          NAME:  choice_mount_path
#   DESCRIPTION:  dialogbox for choice mount path for mounting device
#    PARAMETERS:  @str: mount_path or null
#       RETURNS:  @str: mount_path
#===============================================================================

function choice_mount_path ()
{
    src="${1}"
    dst="${2}"
    _tmp_dst="${3}"
    dialog --backtitle "ASCP" \
        --title "Montowanie zasobów" \
        --inputbox "Wprowadź scieżkę do zamontowania $src
    Sugerowana ścieżka montowania to $dst" 10 50 2> ${_tmp_dst}
    mount_path=$(cat ${_tmp_dst} | head -n 1)
    mount_path_status=$(check_mount_path "${mount_path}")
    EchoLog "mount_path_status ${mount_path_status}"
    if [[ "${mount_path_status}" == "1" ]]; then
        MakeDir "${mount_path}"
        EchoSuccessLog "Choice ${mount_path}"
    else
        if [[ "${mount_path_status}" == "123" ]]; then
            EchoErrorLog "Mount path alredy used ${mount_path}"
            EchoLog "Run dialog for information about problem witch actual choice mount path"
            dialog --backtitle "ASCP - Tomasz Kozubal" \
                --title "Błąd wyboru ścieżki montowania zasobóœ" \
                --msgbox "Ścieżka ${mount_path} jest już używana. Wybierz inny zasobów" 10 50
        elif [[ "${mount_path_status}" == "127" ]]; then
            EchoErrorLog "Empty mount path"
            dialog --backtitle "${PROGNAME}" \
                --title "Błąd wyboru ścieżki montowania zasobów" \
                --msgbox "Ścieżka nie może być pusta" 10 50
        elif [[ "${mount_path_status}" == "124" ]]; then
            EchoErrorLog "Mount path alredy in fstab"
            dialog --backtitle "${PROGNAME}" \
                --title "Błąd wyboru ścieżki montowania zasobów" \
                --msgbox "Ścieżka już istanieje w fstab" 10 50
        fi
        EchoErrorLog "check_mount_path returned ${mount_path_status}"
        EchoLog "Run dialog for choice mount point"
        choice_mount_path "${src}" "${dst}" "${_tmp_dst}"
    fi
}    # ----------  end of function choice_mount_path  ----------


#===  FUNCTION  ================================================================
#          NAME:  check_disk_size
#   DESCRIPTION:  check local disk space on machine
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function check_disk_size ()
{
    _disk_list=$(tempfile)
    _disk_size=$(tempfile)
    find /dev/ -type b -iname 'sd*' | egrep '[0-9]' | sort -u > $_disk_list
    while read device; do
        if [ -b "${device}" ]; then
            dev="${device}"
            df -hTP "${dev}" | egrep '/' >> $_disk_size
        fi
    done < $_disk_list
    while read disk_size; do
        echo "${disk_size}"
        device=$(echo "${disk_size}" | awk {'print $1;'})
        mount_path=$(echo "${disk_size}" | awk {'print $7;'})
        percent=$(echo "${disk_size}" | awk {'print $6;'} | tr -d "%s")
        char="#"
        if [ $percent -lt 30 ]; then
            COLOR="28"
        fi
        if [ $percent -eq 50 ]; then
            COLOR="29"
        fi
        if [ $percent -gt 50 ]; then
            COLOR="32"
        fi
        if [ $percent -gt 80 ]; then
            COLOR="31"
        fi

        out="\\033[0;${COLOR}m"
        for (( COUNTER=0; COUNTER<100; COUNTER++ )); do
            out="${out}${char}"
            if [[ ${percent} == ${COUNTER} ]]; then
                out="${out}\\033[0;33m"
                char="."
            fi
        done
        out="${out}\\033[0m\n"
        echo "${out}"
    done < $_disk_size

}    # ----------  end of function check_disk_size  ----------
