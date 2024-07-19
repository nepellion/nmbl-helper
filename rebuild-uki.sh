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
  exit 1
}

create_kernel_entry() {
  if [[ -z "$1" ]]; then
    prettyprint r "No section provided" >&2
    exit 1
  fi

  local current_section="$1"
  prettyprint y "Creating entry for section $current_section..."

  local kernel=$(find_kernel_for_pkg "$current_section")
  prettyprint b "Found kernel: $kernel"
  
  local pkgbase_dir="$nmbl_dir/$current_section"
  mkdir -p "$pkgbase_dir"

  local booster_img="$pkgbase_dir/booster.img"
  booster build --force --kernel-version ${kernel##/usr/lib/modules/} "$booster_img" || exit 1
  prettyprint b "Built booster image: $booster_img"

  local linux_img="$pkgbase_dir/linux"
  install -Dm644 "${kernel}/vmlinuz" "$linux_img" || exit 1
  prettyprint b "Installed kernel image: $linux_img"

  local efi_file="$esp/EFI/Linux/${current_section}.efi"
  ukify build \
    --config="$ukify_conf" \
    --linux="$linux_img" \
    --initrd="$booster_img" \
    --output="$efi_file" \
  || exit 1
  prettyprint b "Built UKI EFI file: $efi_file"
    
  sbctl sign "$efi_file" || exit 1
  prettyprint b "Signed EFI file."

  local boot_label=${BootLabel:-"Arch linux"}

  # Clean off /boot to form a local ESP path
  efi_file=${efi_file#"$esp"}
  # Replace / with \
  efi_file=${efi_file//\//\\}

  /bin/bash $base_dir/efi-install.sh -l "$boot_label" -F "$efi_file" || exit 1

  prettyprint g "Entry for section $current_section created."
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
          create_kernel_entry "$current_section"
          current_section=
        fi  

        local new_section="${line:1:-1}"
        if pacman -Q "$new_section" > /dev/null 2>&1; then
          current_section="$new_section"
        else
          prettyprint y "Skipped section $new_section, no kernel package found"
        fi
        ;;
      *) eval "$line";;
    esac
  done < "$1"

  if [[ -n "$current_section" ]]; then
    create_kernel_entry "$current_section"
  fi
}

# Create EFI entries from default config
create_kernel_entries "$nmbl_helper_conf"

# Create EFI entries from config directory
for conf in $nmbl_helper_conf_dir/*; do
  create_kernel_entries "$conf"
done