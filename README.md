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
> options Linux and Initrd are ignored, as they get set by discovered kernel packages and booster initramfs images respectively

> [!WARNING]  
> At the very least `Cmdline` needs to be set to proper kernel parameters to boot! (see: https://wiki.archlinux.org/title/Kernel_parameters).  
> You can for example copy these from `/boot/grug/grub.cfg` if you were using grub before (they are the parameters passed to the `linux` executable in the main menu entry, they are mostly there to find and mount the main root partition, after which fstab will be loaded and used to mount the rest)

> [!IMPORTANT]  
> You should also consider adding your respective `Microcode` package, either `amd-ucode` or `intel-ucode` (see: https://wiki.archlinux.org/title/microcode)

### UEFI | efibootmgr

The default EFI boot record is set using `efibootmgr` command from the `efibootmgr` package.

Configuration is done through files in `/etc/nmbl-ukify.conf.d` directory.  
The default file `/etc/nmbl-ukify.conf` should already contain this configuration:
```conf
OSDirLabel="Linux"

[linux]
BootLabel="Arch linux"

[linux-lts]
BootLabel="Arch linux LTS"
```

### Configuration
Variables are read in a simplistic top-down manner. Variables outside a section (start of file) are used as "global" for the rest of the file unless overriden on a per-section basis.

Options:
| Variable      | Default | Description |
|---------------|---------|-------------|
| BootLabel     | `Arch linux` | Boot label visible in the UEFI menu |
| OSDirLabel    | `Linux` | Directory to use in `/boot/EFI` |
| BootPartUUID  | | UUID of the partition containing the `EFI` folder (if not specified lsblk will be used to determine it)|
| KernelModules | | These will be added to the `/etc/ukify.conf` file, in case you need different modules to be pre-loaded for different kernels |

#### Sections
A section per boot record is expected, with it's name matching the used linux kernel package (for example `linux` or `linux-lts`) with supported config values:

> [!TIP]  
> when adding other sections / kernel packages, consider adding partial files to `/etc/nmbl-ukify.conf.d` instead of editing `/etc/nmbl-ukify.conf` to minimize conflicts while updating

## Secure boot

For secure boot to work, you will need to setup keys using `sbctl` (see https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot)

When `sbctl` is available, the hook will automatically sign all UKI EFI files with it.

## Customization

Though the helper is designed to be hands-off, you can run it without the `booster` package. When booster isn't available, `nmbl-helper` will expect there to be a `/var/nmbl/[section]/initramfs.img` file present already. You can add this manually or through another creator (such as mkinitcpio or dracut)

You can also similarly add a custom kernel package. It will be loaded from `/var/nmbl/[section]/vmlinuz`. There should also be a file at `/var/nmbl/[section]/kernel-version` containing the kernel version (only necessary when booster is used)
