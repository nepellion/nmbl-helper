# NMBL helper

NMBL helper scripts and hook for automatically managing directly EFI bootable unified kernel images for Arch Linux.

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
```
[linux]
BootLabel="Arch linux"

[linux-lts]
BootLabel="Arch linux LTS"
```

A section per boot record is expected, with it's name matching the used linux kernel package (for example `linux` or `linux-lts`) with supported config values:
- `BootLabel`: Boot label used for the default EFI boot record (defaults to: `Arch linux`)

> [!TIP]
> when adding other kernel packages, consider adding partial files to `/etc/nmbl-ukify.conf.d` instead of editing `/etc/nmbl-ukify.conf` to minimize conflicts while updating


## Simple setup

With Archlinux installed and bootable, you can run these commands to copy current booted environment to the ukify config.
```
sudo bash -c 'printf "\n%s" "Cmdline=$(cat /proc/cmdline)" >> /etc/ukify.conf'
sudo /usr/lib/nmbl-ukify/rebuild-uki.sh
```

With this, you should now see a new entry in your BIOS/UEFI settings that you should be able to boot into.      