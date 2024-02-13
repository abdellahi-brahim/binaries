#!/bin/bash

if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Backing up SELinux policies and modules..."
semanage export > /root/selinux_policies_backup.txt
semodule -lfull > /root/selinux_modules_backup.txt

remove_module() {
  local module=$1
  echo "Attempting to remove module: $module"
  if semodule -r "$module" 2>/dev/null; then
    echo "Removed $module module successfully."
  else
    echo "Failed to remove $module module. It might be essential or not exist."
  fi
}

echo "Removing non-essential SELinux modules..."
semodule -lfull | while read -r module priority; do
  case "$module" in
    base|login|user)
      echo "Skipping essential module: $module"
      ;;
    *)
      remove_module "$module"
      ;;
  esac
done

echo "Resetting SELinux booleans to their default states..."
semanage boolean -l | while read line; do
  boolean=$(echo "$line" | cut -d' ' -f1)
  default=$(echo "$line" | awk '{print $NF}' | sed 's/[(,)]//g')
  setsebool $boolean $default
done

echo "Initiating filesystem relabel on next reboot..."
touch /.autorelabel

echo "All steps completed. Please reboot your system for the changes to take effect."
