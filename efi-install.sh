#!/bin/bash

show_help()
{
   echo "usage: ./efi-install.sh [options]"
   echo "  -F <file>    EFI file path local to the Boot loader partition"
   echo "  -d <device>  Disk containing boot loader (defaults to df result of '/boot')"
   echo "  -l <label>   Boot entry label"
   echo "  -f           Force new entry when it is already present (defaults to false)"
   echo "  -D           Dry run"
   echo "  -v           Print additional information."
   echo "  -h           Show help/usage."
}

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
      *) echo "$1";;
    esac
  else
    echo "$1"
  fi
}

efi_file=
boot_dev=
entry_name=
force=0
verbose=0
dry_run=0
while getopts "F:d:l:fDvh" option; do
    case $option in
        F) efi_file="$OPTARG";;
        d) boot_dev="$OPTARG";;
        l) entry_name="$OPTARG";;
        f) force=1;;
        v) verbose=1;;
        D) dry_run=1;;
        h) show_help
        exit;;
        \?) echo "Error: Invalid option"
        exit;;
   esac
done

if [[ -z "$efi_file" ]]; then
  prettyprint r "EFI file path was not provided." >&2
  exit
fi

if [[ -z "$entry_name" ]]; then
  prettyprint r "EFI boot entry name was not provided." >&2
  exit
fi

if [[ -z "$boot_dev" ]]; then
  boot_dev=$(df "/boot" --output=source | tail -1)
fi

if [[ -z "$boot_dev" ]]; then
  prettyprint r "Couldn't determine /boot partition and none was provided." >&2
  exit
fi

boot_part_uuid=$(lsblk "$boot_dev" -o PARTUUID | tail -1)
if [[ -z "$boot_part_uuid" ]]; then
  prettyprint r "Couldn't determine /boot partition UUID." >&2
  exit
fi

if [[ $verbose -eq 1 ]]; then
  echo "Found partition UUID ($boot_part_uuid) for disk $boot_dev"
fi

boot_part_disk=
if [[ $boot_dev == *"nvme"* ]]; then
  boot_part_disk="${boot_dev:0:-2}"
else
  boot_part_disk="${boot_dev:0:-1}"
fi

boot_part_num="${boot_dev:0-1}"

if [[ $dry_run -eq 1 ]]; then
  prettyprint b "Will create efibootmgr entry for file '$efi_file' on disk $boot_part_disk part $boot_part_num, with label '$entry_name'"
  exit 0
fi

efi_entry=$(efibootmgr | grep "$boot_part_num,GPT,$boot_part_uuid" | grep -F "$efi_file")
if [[ $force -eq 0 ]] && [[ -n "$efi_entry" ]]; then
  if [[ $verbose -eq 1 ]]; then
    prettyprint b "EFI entry for $efi_file already exists."
  fi
else
  if [[ $verbose -eq 1 ]]; then
    efibootmgr -c -d "$boot_part_disk" -p "$boot_part_num" -L "$entry_name" -l "$efi_file" || exit
  else
    efibootmgr -c -d "$boot_part_disk" -p "$boot_part_num" -L "$entry_name" -l "$efi_file" > /dev/null || exit
  fi

  prettyprint g "Created new EFI entry '$entry_name' for file '$efi_file'"
fi
