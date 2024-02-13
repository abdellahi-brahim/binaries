#!/bin/bash

if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

echo "Removing custom SELinux modules..."
semodule -l | cut -d' ' -f1 | while read -r module; do
  if [[ "$module" != "base" && "$module" != "login" && "$module" != "staff" && "$module" != "user" && "$module" != "webadm" ]]; then
    semodule -r "$module"
    echo "Removed $module module."
  fi
done

echo "Resetting SELinux booleans to default..."
getsebool -a | grep -oP '.*(?= --> on|off)' | while read -r boolean; do
  default_value=$(semanage boolean -l | grep "^$boolean" | awk '{print $NF}')
  setsebool -P $boolean $default_value
  echo "Set $boolean to $default_value."
done

echo "Setting up filesystem relabeling on next reboot..."
touch /.autorelabel

echo "All steps completed. Please reboot your system for the changes to take effect."
