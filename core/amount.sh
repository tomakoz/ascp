#!/bin/bash
#===============================================================================
#
#          FILE:  amount.sh
# 
#         USAGE:  ./amount.sh 
# 
#   DESCRIPTION:  Mount local file system and add to fstab file
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR:  Tomasz Kozubal (), 
#       COMPANY:  Kozubal
#       VERSION:  1.0
#       CREATED:  22.05.2016 16:54:21 CEST
#      REVISION:  ---
#===============================================================================

#===  FUNCTION  ================================================================
#          NAME:  usage
#   DESCRIPTION:  function to show help information about usage of this script
#    PARAMETERS:  
#       RETURNS:  
#===============================================================================
function usage ()
{
    echo -e "Run ${0} to mount local device and add to fstab\n" 
    echo -e "Example: ${0} --whot /dev/sdb1 --where /mnt/sdb1 --how ext4 --when auto\n" 

}    # ----------  end of function usage  ----------

BLKID=$(which blkid)
MOUNT=$(which mount)
UMOUNT=$(which umount)

_partitions=$(tempfile)


#-------------------------------------------------------------------------------
#   check if run script as root, if not script exiting
#-------------------------------------------------------------------------------


#===  FUNCTION  ================================================================
#          NAME:  check_perm
#   DESCRIPTION:  checking if run script as root
#    PARAMETERS:  
#       RETURNS:  bool
#===============================================================================

function check_perm () {

    if [[ "${1}" != "" ]]; then
        uid="0"
    else
        uid="0"
    fi
    if [[ "${UID}" == "${uid}" ]]; then
        echo "1"
    else
        # echo -e "Nie masz odpowiednich uprawnień\n"
        echo "0"
    fi
}    # ----------  end of function check_perm  ----------




#-------------------------------------------------------------------------------
#   checking if script is runing with root access
#-------------------------------------------------------------------------------

function amount () {
    if [[ $(check_perm root) != "1" ]]; then
        echo "Run ${0} as root"
        return 0
    fi

    src="${1}"
    dst="${2}"
    fs_type="${3}"
    if [[ "${dst}" != "" ]]; then
        if [[ ! -d "${dst}" ]]; then
            MakeDir ${dst}
        fi
    fi
    if [[ $(check_mount $dst) == "OK" ]]; then
        EchoError "Destination $dst point is alredy usedis mount"
        return 0
        exit
    fi


    if [[ $(check_mount $src) == "OK" ]]; then

        EchoErrorLog "${src} is mount"
        return 0
        exit
    fi

    EchoMsg "Get information about $src"
    LABEL=$(get_label ${src})
    if [[ "${LABEL}" != "" ]]; then
        EchoSuccess "LABEL: ${LABEL}"
    else
        EchoError "LABEL: ${LABEL}"
    fi
    UUID=$(get_uuid ${src})
    if [[ "${UUID}" != "" ]]; then
        EchoSuccess "UUID: $UUID"
    else
        EchoError "UUID: "
    fi

    TYPE="$(get_fs_type ${src})"
    
    if [[ "${TYPE}" != ""  ]] ; then
        EchoSuccess "Filesystem type: ${TYPE}"
    else
        EchoError "File system not have type"
        exit 127
    fi

    if [[ "${LABEL}" != "" ]]; then
        dialog --backtitle "ASCP" \
            --title "Montowanie zasobów" \
            --yesno "Sugerowan punkt montowania dla urządzenia ${src} to /mnt/${LABEL}\\n
        Checsz pozostawic punkt montowania?" 10 70
        if [[ $(echo $?) == "1" ]]; then
            dst="/mnt/test"
        else
            dst="/mnt/${LABEL}"
        fi
    fi
    
    if [[ "${TYPE}" == "ntfs" ]]; then
        TYPE="ntfs-3g"
        OPTIONS="rw,uid=1000,gid=1000,dmask=2000,fmask=0003"
        DUMP="0"
        PASS="0"

    else
        OPTIONS="defaults"
        DUMP="0"
        PASS="2"
    fi
    export MountPath
    _tmp_mount_path=$(tempfile)
    choice_mount_path "${src}" "${dst}" "${_tmp_mount_path}"
    dst=$(cat ${_tmp_mount_path} | head -n 1)
    dialog --backtitle "ASCP" \
        --title "Montowanie zasobów" \
        --yesno "Czy montować automatycznie przy starcie systemu?" 10 50

    if [[ $(echo $?) != "0" ]]; then
        OPTIONS="${OPTIONS},noauto"
    fi


    CMD="mount ${dst}"
    FSTAB_RULE="UUID=${UUID}\t${dst}\t${TYPE}\t${OPTIONS}\t0\t2"
    EchoSuccessLog "CMD: ${CMD}"
    EchoSuccessLog "add fstab rule ${FSTAB_RULE}"
    echo -e "${FSTAB_RULE}" >> /etc/fstab && EchoSuccessLog "add fstab rule ${FSTAB_RULE}" || EchoErrorLog "add fstab rule ${FSTAB_RULE}"
    dialog --backtitle "${PROGNAME}" \
        --title "Montowanie zasobów" \
        --msgbox "Dodano wpis do pliku /etc/fstab dla zasobu ${src}\n
                 ${FSTAB_RULE}" 10 50
    dialog --backtitle "${PROGNAME}" \
        --title "Montowanie zasobów" \
        --yesno "Czy chcesz teraz zamontować ${dst}?" 10 50
    if [[ $(echo $?) == "0" ]]; then
        eval "${CMD}" && EchoSuccessLog "${CMD}" || EchoErrorLoo "${CMD}"
        if [[ "$(check_mount ${dst})" == "OK" ]]; then
            dialog --backtitle "${PROGNAME}" \
                --title "Montowanie zasobów" \
                --msgbox "Zamontowałęm pomyślnie $src w $dst" 10 50
        fi
    fi


}
