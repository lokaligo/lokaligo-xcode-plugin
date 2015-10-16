#!/bin/bash

# Lokaligo build script for iOS.
# Copyright 2015 Lokaligo

# This file downloads the actual ruby script, and makes sure it is up to date.
# The downloaded ruby script takes care of the import/export process.

set -e

DOWNLOAD_URL="https://lokaligo.com/sdk/lokaligo_build_phase.tar.gz"
if [ -n "${LOKALIGO_DEV}" ]; then
  DOWNLOAD_URL="http://localhost:4000/sdk/lokaligo_build_phase.tar.gz"
fi

OUT_DIR=~/Library/Caches/com.lokaligo
OUT_FILE="${OUT_DIR}/lokaligo_build_phase.tar.gz"
BUILD_FILE="${OUT_DIR}/lokaligo_build_phase.rb"

function download_build_script {
  curl --fail --silent --location --max-time 15 --max-filesize 1048576 --output "${OUT_FILE}" --time-cond "${OUT_FILE}" "${DOWNLOAD_URL}"
  if [ $? -eq 0 ]; then
    touch "${OUT_FILE}"
    tar -xzf "${OUT_FILE}" -C "${OUT_DIR}"
  fi
}

function check_file {
  mkdir -p "${OUT_DIR}"

  if [ ! -f "${OUT_FILE}" ]; then
    download_build_script
  elif test `find "${OUT_FILE}" -mmin +1440`; then
    download_build_script
  fi

  if [ ! -f "${BUILD_FILE}" ]; then
    echo "Skipping lokaligo build phase (could not download the lokaligo build script)."
    exit 0
  fi
}

function check_env_vars {
  if [ -z "$SRCROOT" ]; then
    echo "SRCROOT should be set to the path of your project (i.e. directory where the .xcodeproj file resides)."
    exit 1
  fi

  if [ -z "$LOKALIGO_API_KEY" ]; then
    echo "LOKALIGO_API_KEY should be set."
    exit 0
  fi
}

check_file
check_env_vars

if [ -z "$LOKALIGO_DEV" ]; then
  SRCROOT="${SRCROOT}" LOKALIGO_API_KEY="${LOKALIGO_API_KEY}" CONFIGURATION="Debug" CRASH_ON_ERROR="1" ruby "${BUILD_FILE}"
else
  SRCROOT="${SRCROOT}" LOKALIGO_API_KEY="${LOKALIGO_API_KEY}" CONFIGURATION="Debug" LOKALIGO_DEV="${LOKALIGO_DEV}" CRASH_ON_ERROR="1" ruby "${BUILD_FILE}"
fi
