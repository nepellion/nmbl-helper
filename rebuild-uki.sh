#!/bin/bash

base_dir=$(dirname "$0")
nmbl_dir="/var/nmbl"

ukify_conf="/etc/ukify.conf"
nmbl_helper_conf="/etc/nmbl-helper.conf"
nmbl_helper_conf_dir="/etc/nmbl-helper.d/"

esp="/boot"

prettyprint() {
  local color_clear='\033[0m';
  if [[ -t 1 ]] || [[ -t 2 ]]; then
    case $1 in
      r) local color='\033[0;31m' && printf "${color}%s${color_clear}\n" "$2";;
      g) local color='\033[0;32m' && printf "${color}%s${color_clear}\n" "$2";;
      y) local color='\033[0;33m' && printf "${color}%s${color_clear}\n" "$2";;
      b) local color='\033[0;34m' && printf "${color}%s${color_clear}\n" "$2";;
      p) local color='\033[0;35m' && printf "${color}%s${color_clear}\n" "$2";;
      t) local color='\033[0;36m' && printf "${color}%s${color_clear}\n" "$2";;
      *) echo "$2";;
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
    if ! pacman -Qqo "${kernel}/pkgbase" > /dev/null 2>&1; then
      # if pkgbase does not belong to any package then skip this kernel
      continue
    fi

    read -r pkgbase < "${kernel}/pkgbase"

    if [[ $pkgbase -eq $expected_pkgbase ]]; then
      echo "$kernel"
      return 0
    fi
  done

  prettyprint r "Could not find kernel for package $expected_pkgbase" >&2    
  return 1
}

create_kernel_entry() {
  if [[ -z "$1" ]]; then
    prettyprint r "No section provided" >&2
    exit 1
  fi

  if [[ -z "$2" ]]; then
    prettyprint r "No instance identifier provided" >&2
    exit 1
  fi

  local current_section="$1"
  local instance_identifier="$2"
  local boot_part_uuid="$3"
  prettyprint y "Creating entry for section $current_section..."

  local nmbl_kernel_dir="$nmbl_dir/$current_section"
  mkdir -p "$nmbl_kernel_dir"

  local kernel_ver=
  local linux_img=
  if [[ -e "$nmbl_kernel_dir/vmlinuz" ]] && [[ -e "$nmbl_kernel_dir/kernel-version" ]]; then
    linux_img="$nmbl_kernel_dir/vmlinuz";
    kernel_ver=$(<"$nmbl_kernel_dir/kernel-version")

    prettyprint b "Found custom kernel: $kernel ($nmbl_kernel_dir/vmlinuz $kernel_ver)"
  else
    local kernel=$(find_kernel_for_pkg "$current_section")
    if [[ -n "$kernel" ]]; then
      linux_img="${kernel}/vmlinuz";
      kernel_ver="${kernel##/usr/lib/modules/}"
      prettyprint b "Found kernel: $kernel (package: $current_section)"
    else
      prettyprint r "Kernel not found for package $current_section" >&2
      exit 1
    fi
  fi

  local initramfs_img="$nmbl_kernel_dir/initramfs.img"
  if command -v booster > /dev/null; then
    if [[ -z "$kernel_ver" ]]; then
      prettyprint r "Kernel version not found for package $current_section" >&2
      exit 1
    fi

    booster build --force --kernel-version "$kernel_ver" "$initramfs_img" || exit 1
    prettyprint b "Built booster image: $initramfs_img"
  elif [[ -e "$initramfs_img" ]]; then
    prettyprint y "Using existing initramfs image, because booster isn't available: $initramfs_img"
  else
    prettyprint r "Booster not available, and no initramfs image found: $initramfs_img" >&2
    exit 1
  fi

  local efi_file="$esp/EFI/$instance_identifier/${current_section}.efi"
  ukify build \
    --config="$ukify_conf" \
    --linux="$linux_img" \
    --initrd="$initramfs_img" \
    --output="$efi_file" \
  || exit 1
  prettyprint b "Built UKI EFI file: $efi_file"

  if command -v sbctl > /dev/null; then
    sbctl sign "$efi_file" || exit 1
    prettyprint b "Signed EFI file."
  fi

  local boot_label=${BootLabel:-"Arch linux"}

  # Clean off /boot to form a local ESP path
  efi_file=${efi_file#"$esp"}
  # Replace / with \
  efi_file=${efi_file//\//\\}

  /bin/bash $base_dir/efi-install.sh -l "$boot_label" -F "$efi_file" -u "$boot_part_uuid" || exit 1
}

create_kernel_entries() {
  local current_section=
  while IFS= read -r line
  do
    if [[ -z "$line" ]]; then
      continue
    fi

    case "$line" in 
      \[*\])
        if [[ -n "$current_section" ]]; then
          create_kernel_entry "$current_section" "$OSDirLabel" "$BootPartUUID"
          current_section=
        fi  

        local new_section="${line:1:-1}"
        if pacman -Qi "$new_section" 2>/dev/null > /dev/null; then
          current_section="$new_section"
        elif [[ -e "$nmbl_dir/$new_section/vmlinuz" ]]; then
          current_section="$new_section"
          prettyprint y "Found custom kernel for section $new_section"
        else
          prettyprint y "Skipped section $new_section, no kernel package found"
        fi
        ;;
      *) eval "$line";;
    esac
  done < "$1"

  if [[ -n "$current_section" ]]; then
    create_kernel_entry "$current_section" "$OSDirLabel" "$BootPartUUID"
  fi
}

# Create EFI entries from default config
create_kernel_entries "$nmbl_helper_conf"

# Create EFI entries from config directory
for conf in $nmbl_helper_conf_dir/*; do
  create_kernel_entries "$conf"
done
