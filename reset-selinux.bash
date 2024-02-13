#!/bin/bash

if [ "$(id -u)" -ne "0" ]; then
  echo "This script must be run as root" 1>&2
  exit 1
fi

remove_module() {
  local module=$1
  echo "Attempting to remove module: $module"
  semodule -r "$module" 2>/dev/null
  if [ $? -ne 0 ]; then
    echo "Failed to remove $module module. It might be essential or not exist."
  else
    echo "Removed $module module."
  fi
}

semodule -lfull | while read -r line; do
  module_name=$(echo "$line" | awk '{print $1}')
  case "$module_name" in
    base|login|user)
      echo "Skipping essential module: $module_name"
      ;;
    *)
      remove_module "$module_name"
      ;;
  esac
done

echo "Module removal attempt complete."
