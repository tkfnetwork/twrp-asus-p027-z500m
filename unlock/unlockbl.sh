#!/system/bin/sh
#########################################################################
###############                                           ###############
###############          Bootloader Unlock Tool           ###############
###############           for ASUS ZenPad P027            ###############
###############   by the guy known as diplomatic on XDA   ###############
###############                                           ###############
#########################################################################
#
#

ABORT_MSG="Oops! Something went wrong. Aborting\nYour system has not been modified"
CONFIRM_MSG=
TMP_DIR=unlock_tool_tmp
BACKUP_PATH=/sdcard/unlock_tool
BIN=tool_bin
alias dd="dd bs=4096"

cleanup() {
	rm $TMP_DIR/enc-stage1.bin 2> /dev/null
	rm $TMP_DIR/dec-stage1.bin 2> /dev/null
	rm $TMP_DIR/dec-stage2.bin 2> /dev/null
	rm $TMP_DIR/enc-stage2.bin 2> /dev/null
	rmdir $TMP_DIR 2> /dev/null
	rm -r $BIN 2> /dev/null
}

check_success() {
	eval "$1"
	EC=$?
	if [ $EC -ne 0 ]; then
		echo -e $ABORT_MSG
		echo "Exit code $EC"
		cleanup
		exit 1
	fi
}

# Start
echo
echo		"########################################################################"
echo		"##############                                            ##############"
echo		"##############           Bootloader Unlock Tool           ##############"
echo		"##############            for ASUS ZenPad P027            ##############"
echo		"##############   by the guy known as diplomatic on XDA    ##############"
echo		"##############                                            ##############"
echo		"########################################################################"
echo

if [ "$(id -u)" != "0" ]; then
	echo "This script needs to be run in root mode."
	exit 1
fi

case $(getprop ro.product.model) in 
	P027|P00A)
		# continue
		;;
	*)
		echo	"Your device is not supported"
		exit 1
		;;
esac

echo		"Please make a selection"
echo		"1. Unlock bootloader"
echo		"2. Lock bootloader"
echo

REPLY=
while [ -z "$REPLY" ]; do
	echo -n "> "
	read -r
done
case "$REPLY" in
	1)
		OP=unlock
		;;
	2)
		OP=lock
		;;
	*)
		echo "Bad selection. Goodbye."
		exit 1
		;;
esac

if [ "$OP" == "unlock" ]; then
	CONFIRM_MSG="Yes, I want to unlock"
	echo
	echo -e		"This program will disable image verification in your device, "
	echo -e		"effectively unlocking the bootloader."
	echo -e		"If you understand what this means and the risks and drawbacks involved,"
	echo -e		"please type \"$CONFIRM_MSG\" (case sensitive) at the prompt and"
	echo -e		"press Enter to continue."
	echo -e		"Entering anything else will exit this program."
	echo
else
	CONFIRM_MSG="Yes, I want to lock"
	echo
	echo -e		"This program will enable image verification in your device, "
	echo -e		"effectively locking the bootloader. Before proceding, make sure that"
	echo -e		"you have installed stock firmware on your device or it will not boot."
	echo -e		"If you understand what this means and the risks and drawbacks involved,"
	echo -e		"please type \"$CONFIRM_MSG\" (case sensitive) at the prompt and"
	echo -e		"press Enter to continue."
	echo -e		"Entering anything else will exit this program."
	echo
fi

echo -n "> "; read -r
if [ "$REPLY" != "$CONFIRM_MSG" ]; then
	echo "Goodbye."
	exit 1
fi

# Temp folder
check_success "mkdir -p $TMP_DIR"

# Extract tar archive
echo "Extracting binaries"
check_success "tar -xf /data/local/tmp/tool_bin_arc.tar 2> /dev/null"

# Test encryption
echo "Testing encryption"
check_success "$BIN/sec_tz --test 1>/dev/null 2>/dev/null"

BLKDEVPATH=$($BIN/mtkcfg --getblkdevice)
if [ $? -ne 0 ]; then
	echo -e $ABORT_MSG
	cleanup
	exit 1
fi

echo "Reading bootloader config"
check_success "dd if=$BLKDEVPATH of=$TMP_DIR/enc-stage1.bin count=2 2> /dev/null"

echo "Decrypting"
check_success "$BIN/sec_tz --decrypt $TMP_DIR/enc-stage1.bin $TMP_DIR/dec-stage1.bin >/dev/null"

echo "Verifying"
LOCKSTATE=
check_success "LOCKSTATE=$($BIN/mtkcfg --getlock $TMP_DIR/dec-stage1.bin 2> /dev/null)"

if [ "$OP" == "unlock" ]; then
	if [ "$LOCKSTATE" == "unlocked" ]; then
		echo "Your device is already unlocked"
		cleanup
		exit 1
	fi

	echo "Backing up bootloader config to $BACKUP_PATH/encrypt-locked.bin"
	mkdir -p $BACKUP_PATH
	cp -f $TMP_DIR/enc-stage1.bin $BACKUP_PATH/encrypt-locked.bin

else
	if [ "$LOCKSTATE" == "locked" ]; then
		echo "Your device is already locked"
		cleanup
		exit 1
	fi
fi

echo "Setting lock state"
check_success "$BIN/mtkcfg --$OP $TMP_DIR/dec-stage1.bin $TMP_DIR/dec-stage2.bin >/dev/null"

echo "Encrypting"
check_success "$BIN/sec_tz --encrypt $TMP_DIR/dec-stage2.bin $TMP_DIR/enc-stage2.bin >/dev/null"

echo "Saving bootloader config"
check_success "dd if=$TMP_DIR/enc-stage2.bin of=$BLKDEVPATH 2> /dev/null"
sync

cleanup

echo "Done!"
echo "Please reboot your device."
