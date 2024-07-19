# NMBL helper

NMBL helper scripts and hook for automatically managing directly EFI bootable unified kernel images for Arch Linux.

## Basic setup

> [!IMPORTANT]  
> If you don't want to tinker with initramfs images, don't forget to install the `booster` package, so that they are built automatically

With Archlinux installed and bootable, you can run these commands to copy current booted environment to the ukify config.
```bash
sudo bash -c 'printf "\n%s" "Cmdline=$(cat /proc/cmdline)" >> /etc/ukify.conf'
sudo /usr/lib/nmbl-ukify/rebuild-uki.sh
```

With this, you should now see a new entry in your BIOS/UEFI settings that you should be able to boot into.

## Configuration

### UKI | systemd-ukify

The UKI building is based on the `ukify` command from the `systemd-ukify` package, and as such will follow standard configuration through the `/etc/ukify.conf` file.
see https://www.freedesktop.org/software/systemd/man/latest/ukify.html and/or https://wiki.archlinux.org/title/Unified_kernel_image#ukify  

> [!WARNING]  
> At the very least `Cmdline` needs to be set to proper kernel parameters to boot! you can for example copy these from `/boot/grug/grub.cfg` if you were using grub before (they are the parameters passed to the `linux` executable in the main menu entry, they are mostly necessary to find and mount the main root partition, after which fstab will take over)

> [!IMPORTANT]  
> You should also consider adding `Microcode` as either `/boot/amd-ucode.img` or `/boot/intel-ucode.img` from their respective packages (see: https://wiki.archlinux.org/title/microcode)

> [!NOTE]  
> options Linux and Initrd are overridden by discovered kernel packages and booster initramfs images respectively

### UEFI | efibootmgr

The default EFI boot record is set using `efibootmgr` from the `efibootmgr` package.

Configuration is done through files in `/etc/nmbl-ukify.conf.d` directory.  
The default configuration file `/etc/nmbl-ukify.conf` already contains these defaults:
```conf
[linux]
BootLabel="Arch linux"

[linux-lts]
BootLabel="Arch linux LTS"
```

A section per boot record is expected, with it's name matching the used linux kernel package (for example `linux` or `linux-lts`) with supported config values:
- `BootLabel`: Boot label used for the default EFI boot record (defaults to: `Arch linux`)

> [!TIP]  
> when adding other kernel packages, consider adding partial files to `/etc/nmbl-ukify.conf.d` instead of editing `/etc/nmbl-ukify.conf` to minimize conflicts while updating

## Secure boot

For secure boot to work, you will need to setup keys using `sbctl` (see https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)

When `sbctl` is available, the hook will automatically sign all UKI EFI files with it.

## Customization

Though the helper is designed to be hands-off, you can run it without the `booster` package. When booster isn't available, `nmbl-helper` will expect there to be a `/var/nmbl/[section]/initramfs.img` file present already. You can add this manually or through another creator (such as mkinitcpio or dracut)

You can also similarly add a custom kernel package. It will be loaded from `/var/nmbl/[section]/vmlinuz`. There should also be a file at `/var/nmbl/[section]/kernel-version` containing the kernel version (only necessary when booster is used)