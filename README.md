# TWRP Recovery and Root for ASUS ZenPad 10 3S (P027 Z500M) Helper

This tool is designed to simplify the process of unlocking (and rooting). It's aim is to combine all the great work from the XDA forums into one simple to use script

## Usage

You will need ADB and FASTBOOT installed.

Enable [ADB debugging in the developer menu](https://developer.android.com/studio/command-line/adb#Enabling) and connect your device

Clone this repo.

```bash
$ git clone https://github.com/tkfnetwork/twrp-asus-p027-z500m.git
```

Run the script

```bash
$ sh init.sh
```

or

```bash
$ ./init.sh
```

Select your device from the first menu that appears

```bash
1) <device_serial_number>      <device_status>
2) <device_serial_number>      <device_status>
3) <device_serial_number>      <device_status>
Please select a device:
```

### Steps

The menu items provided should follow the steps needed to unlocking this device.

```bash
1) Reboot to bootloader
2) Boot recovery
3) Lock/Unlock
4) Install Magisk
5) Reboot to device
6) Restore firmware
Choose what to do:
```

#### 1. Reboot to bootloader

First reboot to the bootloader. This is so we can then boot to TWRP.
P027 uses fastboot, so this should now be showing on the screen as

```
= > fastboot mode...
```

#### 2. Boot to recovery

Next, we will boot to the recovery. This will boot (temporarily, more on that later) to the specific version of TWRP that works with this device (as created by the great work on XDA).

Keep an eye on the device, it will show the "teamwin recovery project" screen. Once it has loaded the GUI (you will see a bunch of options) move on to the next step. You shouldn't need to interact with the device at this point.

#### 3. Lock/Unlock

Now we unlock the bootloader. Running this step will copy and execute the script written by `diplomatic`. Follow the onscreen instructions.

```bash
########################################################################
##############                                            ##############
##############           Bootloader Unlock Tool           ##############
##############            for ASUS ZenPad P027            ##############
##############   by the guy known as diplomatic on XDA    ##############
##############                                            ##############
########################################################################

WARNING: linker: Warning: unable to normalize ""
WARNING: linker: Warning: unable to normalize ""
Please make a selection
1. Unlock bootloader
2. Lock bootloader

>
```

If you want to quit this screen, then type something other than `1` or `2`.

#### 3.a. Install TWRP (manual step)

**There is no way currently to install images via the TWRP cli so this is a manual step.**

The TWRP recovery image was already sent to the device in the previous step so we now need to install it. To do this you will need to interact with the device screen. Make sure you are at the home screen (you can navigate there by pressing the middle button at the bottom of the screen)

1. Select "Install"
2. Select "Install image" (button at the bottom right of the screen)
3. Navigate to `/sdcard/installs`
4. Select `twrp-3.2.1-0z500m.img`
5. Choose "Recovery" in the radio selection
6. Swipe to install

This should only take a few seconds to complete. **Don't reboot yet!**

#### 4. Install Magisk

Running this step will copy Magisk to the device and automatically install it.

#### 5. Reboot to device

Congratulations! you are done and can reboot to the system. Should you get in to a bootloop you can restore the original firmware via step 6

#### 6. Restore Firmware (optional)

## Credits

This script was made possible thanks to the resources provided by the XDA community.

## Resources

- https://linuxcommandlibrary.com/man/fastboot
- https://twrp.me/faq/openrecoveryscript.html
- TWRP Recovery ASUS ZenPad 3S 10 Z500M: https://forum.xda-developers.com/t/twrp-recovery-asus-zenpad-3s-10-z500m.3758333/
- [VIDEO] How to Unlock Bootloader and Install TWRP ASUS ZenPad 3S 10 Z500M: https://forum.xda-developers.com/t/video-how-to-unlock-bootloader-and-install-twrp-asus-zenpad-3s-10-z500m.4446519/
- https://github.com/topjohnwu/Magisk
