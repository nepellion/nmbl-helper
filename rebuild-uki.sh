#!/bin/bash

base_dir=$(dirname "$0")
nmbl_dir="/var/nmbl"

ukify_conf="/etc/ukify.conf"
nmbl_helper_conf="/etc/nmbl-helper.conf"
nmbl_helper_conf_dir="/etc/nmbl-helper.d/"

esp="/boot"

prettyprint() {
  local color_clear='\033[0m'
  if [[ -t 1 ]] || [[ -t 2 ]]; then
    case $1 in
    r) local color='\033[0;31m' && printf "${color}%s${color_clear}\n" "$2" ;;
    g) local color='\033[0;32m' && printf "${color}%s${color_clear}\n" "$2" ;;
    y) local color='\033[0;33m' && printf "${color}%s${color_clear}\n" "$2" ;;
    b) local color='\033[0;34m' && printf "${color}%s${color_clear}\n" "$2" ;;
    p) local color='\033[0;35m' && printf "${color}%s${color_clear}\n" "$2" ;;
    t) local color='\033[0;36m' && printf "${color}%s${color_clear}\n" "$2" ;;
    *) echo "$2" ;;
    esac
  else
    echo "$2"
  fi
}

mapfile -d '' kernels < <(find /usr/lib/modules -maxdepth 1 -type d ! -name "modules" -print0)

find_kernel_for_pkg() {
  if [[ -z "$1" ]]; then
    prettyprint r "No kernel package name provided" >&2
    exit 1
  fi

  local expected_pkgbase=$1
  for kernel in "${kernels[@]}"; do
    if ! pacman -Qqo "${kernel}/pkgbase" >/dev/null 2>&1; then
      # if pkgbase does not belong to any package then skip this kernel
      continue
    fi

    read -r pkgbase <"${kernel}/pkgbase"

    if [[ "$pkgbase" == "$expected_pkgbase" ]]; then
      echo "$kernel"
      return 0
    fi
  done

  prettyprint r "Could not find kernel for package $expected_pkgbase" >&2
  return 1
}

# Create kernel entry
# $1: Kernel package name
# $2: Boot partition UUID (optional, required if not found by lsblk)
# $3: KernelModules (optional)
# $4: EFI subdir name (defaults to 'Linux')
# $5: BootLabel (defaults to 'Arch linux')
create_kernel_entry() {
  if [[ -z "$1" ]]; then
    prettyprint r "No kernel package name (configuration section) provided" >&2
    exit 1
  fi

  if [[ -z "$4" ]]; then
    prettyprint b "No OSDirLabel provided for section $1, defaulting to 'Linux'."
  fi

  if [[ -z "$5" ]]; then
    prettyprint b "No BootLabel provided for section $1, defaulting to 'Arch linux'."
  fi

  local kernel_package="$1"
  local boot_part_uuid="$2"
  local kernel_modules="$3"
  local efi_os_dir_label=${4:-"Linux"}
  local boot_label=${5:-"Arch linux"}

  prettyprint y "Creating entry for section $kernel_package..."
  local nmbl_kernel_dir="$nmbl_dir/$kernel_package"
  mkdir -p "$nmbl_kernel_dir"

  local kernel_ver=
  local linux_img=
  if [[ -e "$nmbl_kernel_dir/vmlinuz" ]] && [[ -e "$nmbl_kernel_dir/kernel-version" ]]; then
    linux_img="$nmbl_kernel_dir/vmlinuz"
    kernel_ver=$(<"$nmbl_kernel_dir/kernel-version")

    prettyprint b "Found custom kernel: $kernel ($nmbl_kernel_dir/vmlinuz $kernel_ver)"
  else
    local kernel=$(find_kernel_for_pkg "$kernel_package")
    if [[ -n "$kernel" ]]; then
      linux_img="${kernel}/vmlinuz"
      kernel_ver="${kernel##/usr/lib/modules/}"
      prettyprint b "Found kernel: $kernel (package: $kernel_package, ver: $kernel_ver)"
    else
      prettyprint r "Kernel not found for package $kernel_package" >&2
      exit 1
    fi
  fi

  local booster_cfg="$nmbl_kernel_dir/booster.yaml"
  local initramfs_img="$nmbl_kernel_dir/initramfs.img"
  if command -v booster >/dev/null; then
    if [[ -z "$kernel_ver" ]]; then
      prettyprint r "Kernel version not found for package $kernel_package" >&2
      exit 1
    fi

    cp /etc/booster.yaml "$booster_cfg"
    if [[ -n "$kernel_modules" ]]; then
      prettyprint b "Additional kernel modules '$kernel_modules' added to the booster configuration"
      echo "modules_force_load: $kernel_modules" >>"$booster_cfg"
    fi

    booster build --force --kernel-version "$kernel_ver" --config "$booster_cfg" "$initramfs_img" || exit 1
    prettyprint b "Built booster image: $initramfs_img"
  elif [[ -e "$initramfs_img" ]]; then
    prettyprint y "Using existing initramfs image, because booster isn't available: $initramfs_img"
  else
    prettyprint r "Booster not available, and no initramfs image found: $initramfs_img" >&2
    exit 1
  fi

  local efi_file="$esp/EFI/$efi_os_dir_label/${kernel_package}.efi"
  ukify build \
    --config="$ukify_conf" \
    --linux="$linux_img" \
    --initrd="$initramfs_img" \
    --output="$efi_file" ||
    exit 1
  prettyprint b "Built UKI EFI file: $efi_file"

  if command -v sbctl >/dev/null; then
    sbctl sign "$efi_file" || exit 1
    prettyprint b "Signed EFI file."
  fi

  # Clean off /boot to form a local ESP path
  efi_file=${efi_file#"$esp"}
  # Replace / with \
  efi_file=${efi_file//\//\\}

  /bin/bash $base_dir/efi-install.sh -l "$boot_label" -F "$efi_file" -u "$boot_part_uuid" || exit 1
}

create_kernel_entries() {
  local current_section=
  local is_global=y
  local GlobalOSDirLabel=
  local GlobalBootPartUUID=
  local GlobalKernelModules=

  function write_entry_with_global_fallbacks() {
    local kernel_package="$current_section"
    local boot_part_uuid="${BootPartUUID:-$GlobalBootPartUUID}"
    local kernel_modules="${KernelModules:-$GlobalKernelModules}"
    local os_dir_label="${OSDirLabel:-$GlobalOSDirLabel}"
    local boot_label="${BootLabel:-$GlobalBootLabel}"

    create_kernel_entry "$kernel_package" "$boot_part_uuid" "$kernel_modules" "$os_dir_label" "$boot_label"

    BootLabel=
    OSDirLabel=
    BootPartUUID=
    KernelModules=
  }

  while IFS= read -r line; do
    if [[ -z "$line" ]]; then
      continue
    fi

    case "$line" in
    \[*\])
      if [[ "$is_global" == "y" ]]; then
        GlobalOSDirLabel="$OSDirLabel"
        GlobalBootPartUUID="$BootPartUUID"
        GlobalKernelModules="$KernelModules"
        is_global=n
      fi

      if [[ -n "$current_section" ]]; then
        write_entry_with_global_fallbacks
      fi

      local new_section="${line:1:-1}"
      if pacman -Qi "$new_section" 2>/dev/null >/dev/null; then
        current_section="$new_section"
      elif [[ -e "$nmbl_dir/$new_section/vmlinuz" ]]; then
        current_section="$new_section"
        prettyprint y "Found custom kernel for section $new_section"
      else
        current_section=
        prettyprint y "Skipped section $new_section, no kernel package found"
      fi
      ;;
    *) eval "$line" ;;
    esac
  done <"$1"

  if [[ -n "$current_section" ]]; then
    prettyprint y "Creating final entry of file: section $current_section..."
    write_entry_with_global_fallbacks
  fi
}

# Create EFI entries from default config
create_kernel_entries "$nmbl_helper_conf"

# Create EFI entries from config directory
for conf in $nmbl_helper_conf_dir/*; do
  create_kernel_entries "$conf"
done
