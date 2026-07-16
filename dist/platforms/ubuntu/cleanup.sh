#!/usr/bin/env bash

#
# Run cleanup
#

# Clean up an existing floating license
if [[ -f /floating_license.txt ]]; then
  echo "Found provisioned floating license, returning it..."
  FLOATING_LICENSE=$(cat /floating_license.txt)
  /opt/unity/Editor/Data/Resources/Licensing/Client/Unity.Licensing.Client --return-floating "$FLOATING_LICENSE"
  echo "Returned floating license: \"$FLOATING_LICENSE\""
  rm /floating_license.txt
fi
