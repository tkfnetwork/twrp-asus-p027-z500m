#!/bin/sh

MODEL="ASUS ZenPad 10 3S (P027 Z500M)"

RED="\e[31m"
YELLOW="\e[33m"
YELLOW_BOLD="\e[1;33m"
GREEN="\e[32m"
ENDCOLOR="\e[0m"

ADB=$(which adb)
FASTBOOT=$(which fastboot)

VALID=

DEVICES=( )
CURRENT_DEVICE=

sync_device_status() {
    mapfile -t DEVS < <($ADB devices)
    ADB_DEVS=${DEVS[@]:1}
    mapfile -t FASTBOOT_DEVICES < <($FASTBOOT devices)

    for DEV in "${ADB_DEVS[@]}"; do
        if [ -n "$DEV" ]; then
            DEVICE=($DEV)

            if [[ "${DEVICE[0]}" == "${CURRENT_DEVICE[0]}" ]]; then
                CURRENT_DEVICE=("${DEVICE[@]}")
            fi

            DEVICES+=("$DEV")
        fi
    done

    for DEV in "${FASTBOOT_DEVICES[@]}"; do

        if [ -n "$DEV" ]; then
            DEVICE=($DEV)

            if [[ "${DEVICE[0]}" == "${CURRENT_DEVICE[0]}" ]]; then
                CURRENT_DEVICE=("${DEVICE[@]}")
            fi

            DEVICES+=("$DEV")
        fi
    done
}

adb_current_device() {
    $ADB -s "${CURRENT_DEVICE[0]}" "$@"
}

fastboot_current_device() {
    $FASTBOOT -s "${CURRENT_DEVICE[0]}" "$@"
}

twrp_current_device() {
    adb_current_device shell twrp "$@"
}


is_valid() {
    if [ -z "$VALID" ]; then
        exit 1;
    fi;
}

repeat() {
	local start=1
	local end=${1:-80}
	local str="${2:-=}"
	local range=$(seq $start $end)
	for i in $range ; do echo -n "${str}"; done
}

divider() {
    repeat $(expr length "$@") '-'
}

title() {
    echo -e ""
    echo -e "$YELLOW_BOLD$@$ENDCOLOR"
    divider "$@"
    echo -e ""
}

warning() {
    echo -e "$YELLOW$@$ENDCOLOR"
    echo -e ""
}

error(){
    echo -e "$RED$@$ENDCOLOR"
    echo -e ""
}

success(){
    echo -e "$GREEN$@$ENDCOLOR"
    echo -e ""
}

print() {
    echo -e "$@"
    echo -e ""
}

printWithDivider() {
    echo -e "$@"
    divider "$@"
    echo -e ""
}

checkDependencies() {
    if [ -z "$ADB" ]; then
        error "ADB was not found"
        exit 1;
    fi

    if [ -z "$FASTBOOT" ]; then
        error "FASTBOOT was not found, please install."
        exit 1;
    fi
    
    sync_device_status

    if [[ ${#DEVICES[@]} -eq 0 ]]; then
        error "No devices found"
        exit 1;
    fi

    VALID="VALID"
    is_valid

    success "Done!"
}

wait_for_status() {
    WAITING=true
    while [ $WAITING ]; do
        if [ "${CURRENT_DEVICE[1]}" == "$1" ]; then
            WAITING=false
            break;
        else
            sync_device_status
        fi
    done
}

rebootToBootloader() {
    sync_device_status
    if [ "${CURRENT_DEVICE[1]}" == "fastboot" ]; then
        success "Skipped!"
        return
    fi

    adb_current_device reboot bootloader 2> /dev/null
    wait_for_status "fastboot"

    success "Done!"
}

fastbootToTwrp(){
    sync_device_status
    if [ "${CURRENT_DEVICE[1]}" == 'recovery' ]; then
      success "Skipped!"
      return
    fi

    fastboot_current_device boot ./installs/twrp-3.2.1-0-z500m.img 2> /dev/null
    wait_for_status "recovery"

    success "Done!"
}

copyUnlockFiles() {
    printf "\n"
    adb_current_device push ./unlock/* /data/local/tmp/
}

copyInstalls() {
    adb_current_device push ./installs/ /sdcard/
}

copyRestores() {
    adb_current_device push ./restore/ /sdcard/
}

mountSystem() {
    twrp_current_device mount /system
}

bootToLoader() {
    printf "Rebooting to bootloader..."

    sync_device_status
    if [ "${CURRENT_DEVICE[1]}" == "fastboot" ]; then
        warning "Boot to recovery first"
        return
    fi
    
    printf " %s\n" "$(rebootToBootloader)"
}

bootToRecovery() {
    printf "Booting to recovery (TWRP)..."

    sync_device_status
    if [ "${CURRENT_DEVICE[1]}" != "fastboot" ]; then
        warning "Boot to bootloader first"
        return
    fi

    printf " %s\n" "$(fastbootToTwrp)"
}

lockUnlock() {
    sync_device_status
    if [ "${CURRENT_DEVICE[1]}" != "recovery" ]; then
        warning "Device must be in recovery"
        return
    fi

    printf "Copying unlock files..."
    printf " %s\n" "$(copyUnlockFiles)"

    printf "Mounting system..."
    mountSystem

    printf "Running lock/unlock..."
    adb_current_device shell "export LD_LIBRARY_PATH=/system/vendor/lib64:$LD_LIBRARY_PATH && sh /data/local/tmp/unlockbl.sh"
}

installMagisk() {
    printf "Installing Magisk..."
    copyInstalls
    twrp_current_device "install /sdcard/installs/Magisk-v21.4.zip"
}

restoreFirmware(){
    printf "Restoring firmware..."
    copyRestores
    twrp_current_device install /sdcard/restore/UL-P027-WW-14.0210.1806.33-user.zip
}

rebootToDevice() {
    printf "Rebooting to system..."

    sync_device_status

    if [ "${CURRENT_DEVICE[1]}" == "fastboot" ]; then
        warning "Boot to recovery first"
        return
    fi

    if [ "${CURRENT_DEVICE[1]}" == "device" ]; then
        success "Skipped!"
        return
    fi

    adb_current_device reboot

    wait_for_status "device"
    success "Done!"
}

title "$MODEL Recovery Helper"

warning "Disclaimer: This script is intended to aid the process of rooting $MODEL, but comes with no warranties or guarantees that it won't damage your device. Use at your own risk!"
warning "Make sure you backup all your data..."
print Credits: This script was made possible thanks to the resources provided by the XDA community. Special thanks to the following threads on XDA:
echo "- TWRP Recovery ASUS ZenPad 3S 10 Z500M: https://forum.xda-developers.com/t/twrp-recovery-asus-zenpad-3s-10-z500m.3758333/"
print "- [VIDEO] How to Unlock Bootloader and Install TWRP ASUS ZenPad 3S 10 Z500M: https://forum.xda-developers.com/t/video-how-to-unlock-bootloader-and-install-twrp-asus-zenpad-3s-10-z500m.4446519/"
printWithDivider "Please proceed with caution and follow the steps carefully."

printf "Checking for ADB and FASTBOOT..."
checkDependencies

PS3="Please select a device:"

select DEVICE in "${DEVICES[@]}"
do
    CURRENT_DEVICE=(${DEVICES[$REPLY - 1]})

    PS3="Choose what to do:"

    CHOICES=("Reboot to bootloader" "Boot recovery" "Lock/Unlock" "Install Magisk" "Reboot to device" "Restore firmware")

    select CHOICE in "${CHOICES[@]}"
    do
        case $CHOICE in
            "Reboot to bootloader")
                bootToLoader
                ;;
            "Boot recovery")
                bootToRecovery
                ;;
            "Lock/Unlock")
                lockUnlock
                ;;
            "Install Magisk")
                installMagisk
                ;;
            "Reboot to device")
                rebootToDevice
                ;;
            "Restore firmware")
                restoreFirmware
                ;;
            *) 
                echo "Invalid option $REPLY"
                ;;
        esac
    done
    break;
done