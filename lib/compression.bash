#!/bin/bash

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=lib/plugin.bash
. "${DIR}/plugin.bash"

validate_compression() {
  local COMPRESSION="$1"

  VALID_COMPRESSIONS=(none tgz zip)
  for VALID in "${VALID_COMPRESSIONS[@]}"; do
    if [ "${COMPRESSION}" = "${VALID}" ]; then
      return 0
    fi
  done

  return 1
}

compression_active() {
  local COMPRESSION=''
  COMPRESSION="$(plugin_read_config COMPRESSION 'none')"

  [ "${COMPRESSION}" != 'none' ]
}

compress() {
  local COMPRESSED_FILE="$1"
  local FILE="$2"

  local COMPRESSION=''
  COMPRESSION="$(plugin_read_config COMPRESSION 'none')"

  echo "Compressing ${COMPRESSED_FILE} with ${COMPRESSION}..."

  if [ "${COMPRESSION}" = 'tgz' ]; then
    if is_absolute_path "${COMPRESSED_FILE}"; then
      tar czPf "${FILE}" "${COMPRESSED_FILE}"
    else
      tar czf "${FILE}" "${COMPRESSED_FILE}"
    fi
  elif [ "${COMPRESSION}" = 'zip' ]; then
    if is_absolute_path "${COMPRESSED_FILE}"; then
      local COMPRESS_DIR
      COMPRESS_DIR="$(dirname "${COMPRESSED_FILE}")"
      echo "Shifting to absolute path ${COMPRESS_DIR}"
      pushd "${COMPRESS_DIR}" || exit 1
      # because ZIP complains if the file does not end with .zip
      zip -r "${FILE}.zip" "${COMPRESSED_FILE}"
      popd || exit 1
      mv "${COMPRESS_DIR}/${FILE}.zip" "${FILE}"
    else
      # because ZIP complains if the file does not end with .zip
      zip -r "${FILE}.zip" "${COMPRESSED_FILE}"
      mv "${FILE}.zip" "${FILE}"
    fi
  fi
}

uncompress() {
  local FILE="$1"
  local RESTORE_PATH="$2"

  local COMPRESSION=''
  COMPRESSION="$(plugin_read_config COMPRESSION 'none')"

  echo "Cache is compressed, uncompressing with ${COMPRESSION}..."

  if [ "${COMPRESSION}" = 'tgz' ]; then
    if is_absolute_path "${RESTORE_PATH}"; then
      tar xzPf "${FILE}"
    else
      tar xzf "${FILE}"
    fi
  elif [ "${COMPRESSION}" = 'zip' ]; then
    if is_absolute_path "${RESTORE_PATH}"; then
      local RESTORE_DIR
      RESTORE_DIR="$(dirname "${RESTORE_PATH}")"
      echo "Shifting to absolute path ${RESTORE_DIR}"
      mkdir -p "${RESTORE_DIR}"
      mv "${FILE}" "${RESTORE_DIR}/${FILE}.zip"
      pushd "${RESTORE_DIR}" || exit 1
      unzip -o "${FILE}.zip"
      rm "${FILE}.zip"
      popd || exit 1
    else
      # because ZIP complains if the file does not end with .zip
      mv "${FILE}" "${FILE}.zip"
      unzip -o "${FILE}.zip"
    fi
  fi
}

is_absolute_path() {
  local FILEPATH="${1}"
  [ "${FILEPATH:0:1}" = "/" ]
}
