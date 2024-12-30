#!/usr/bin/env bash

# if blankproject folder doesn't exist create it
if [ ! -d "/BlankProject" ]; then
  mkdir /BlankProject
fi
# if blankproject folder doesn't exist create it
if [ ! -d "/BlankProject/Assets" ]; then
  mkdir /BlankProject/Assets
fi

if [[ -n "$UNITY_SERIAL" && -n "$UNITY_EMAIL" && -n "$UNITY_PASSWORD" ]]; then
  #
  # SERIAL LICENSE MODE
  #
  # This will activate unity, using the serial activation process.
  #
  echo "Requesting activation"

  # Loop the unity-editor call until the license is activated with exponential backoff and a maximum of 5 retries
  retry_count=0

  # Initialize delay to 15 seconds
  delay=15

  # Loop until UNITY_EXIT_CODE is 0 or retry count reaches 5
  while [[ $retry_count -lt 5 ]]
  do
    # Activate license
    unity-editor \
      -logFile /dev/stdout \
      -quit \
      -serial "$UNITY_SERIAL" \
      -username "$UNITY_EMAIL" \
      -password "$UNITY_PASSWORD" \
      -projectPath "/BlankProject"

    # Store the exit code from the verify command
    UNITY_EXIT_CODE=$?

    # Check if UNITY_EXIT_CODE is 0
    if [[ $UNITY_EXIT_CODE -eq 0 ]]
    then
      echo "Activation successful"
      break
    else
      # Increment retry count
      ((retry_count++))

      echo "::warning ::Activation failed, attempting retry #$retry_count"
      echo "Activation failed, retrying in $delay seconds..."
      sleep $delay

      # Double the delay for the next iteration
      delay=$((delay * 2))
    fi
  done

  if [[ $retry_count -eq 5 ]]
  then
    echo "Activation failed after 5 retries"
  fi

elif [[ -n "$UNITY_LICENSING_SERVER" ]]; then
  #
  # Custom Unity License Server
  #
  echo "Adding licensing server config"

  # Loop the unity-editor call until the license is activated with exponential backoff and a maximum of 5 retries
  retry_count=0

  # Initialize delay to 15 seconds
  delay=15

  while [[ $retry_count -lt 5 ]]
  do
    # Activate license
    activation_output=$(/opt/unity/Editor/Data/Resources/Licensing/Client/Unity.Licensing.Client --acquire-floating)

    # Store the exit code from the verify command
    UNITY_EXIT_CODE=$?

    echo "---------- Activation output ----------"
    echo "$activation_output"
    echo "---------------------------------------"

    # Check if UNITY_EXIT_CODE is 0 AND activation_output contains the phrase "Expires"
    if [[ $UNITY_EXIT_CODE -eq 0 && $activation_output == *"Expires"* ]]
    then
      echo "Activation successful"
      break
    else
      # Increment retry count
      ((retry_count++))

      echo "::warning ::Activation failed, attempting retry #$retry_count"
      echo "Activation failed, retrying in $delay seconds..."
      sleep $delay

      # Double the delay for the next iteration
      delay=$((delay * 2))
    fi
  done

  if [[ $retry_count -eq 5 ]]
  then
    echo "Activation failed after 5 retries"
    UNITY_EXIT_CODE=1
  else
    export FLOATING_LICENSE=$(echo "$activation_output" | tail -1 | sed -e 's,.* \([-0-9a-f]\{36\}\).*,\1,')
    echo "Floating license acquired: \"$FLOATING_LICENSE\""
  fi

else
  #
  # NO LICENSE ACTIVATION STRATEGY MATCHED
  #
  # This will exit since no activation strategies could be matched.
  #
  echo "License activation strategy could not be determined."
  echo ""
  echo "Visit https://game.ci/docs/github/activation for more"
  echo "details on how to set up one of the possible activation strategies."

  echo "::error ::No valid license activation strategy could be determined. Make sure to provide UNITY_EMAIL, UNITY_PASSWORD, and either a UNITY_SERIAL \
or UNITY_LICENSE. Otherwise please use UNITY_LICENSING_SERVER. See more info at https://game.ci/docs/github/activation"

  # Immediately exit as no UNITY_EXIT_CODE can be derived.
  exit 1;

fi

#
# Display information about the result
#
if [ $UNITY_EXIT_CODE -eq 0 ]; then
  # Activation was a success
  echo "Activation complete."
else
  # Activation failed so exit with the code from the license verification step
  echo "Unclassified error occured while trying to activate license."
  echo "Exit code was: $UNITY_EXIT_CODE"
  echo "::error ::There was an error while trying to activate the Unity license."
  exit $UNITY_EXIT_CODE
fi
