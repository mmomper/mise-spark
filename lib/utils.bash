#!/usr/bin/env bash
#
# Common utilities for asdf-vm bin commands.

set -euo pipefail

GH_REPO="https://github.com/apache/spark"
SPARK_ARCHIVE_URL='https://archive.apache.org/dist/spark'
TOOL_NAME='spark'
TOOL_TEST='spark --help'

DEFAULT_CURL_OPTS=(-fsSL)

##############################################
# Print error message with generalized format.
# Globals:
# Arguments:
#   - Error message
# Outputs:
#   A defined error message text with exit code 1.
##############################################
fail() {
  echo -e "asdf-$TOOL_NAME: $*"
  exit 1
}

###########################################
# List all available Apache Spark versions.
# Globals:
#   None
# Arguments:
#   - Apache spark archive HTML content or the HTML file path.
# Outputs:
#   A space-delimited version string.
###########################################
list_all_versions() {
  local archive_arg="${1:-}"
  local archive_src=''

  if [[ -z "${archive_arg}" ]]; then
    echo ""
    return
  fi

  if [[ -f "${archive_arg}" ]]; then
    archive_src="$(cat "${archive_arg}")"
  else
    archive_src="${archive_arg}"
  fi

  echo "${archive_src}" |
    { grep -Eo '<a href="spark-[0-9]+\.[0-9]+\.[0-9]+(\-[a-z0-9]+)?\/">' || :; } |
    sed -E 's/^<a href="spark-(.+)\/">$/\1/g' |
    xargs
}

download_release() {
  local version filename url
  version="$1"
  filename="$2"

  # TODO: Adapt the release URL convention for spark
  url="$GH_REPO/archive/v${version}.tar.gz"

  echo "* Downloading $TOOL_NAME release $version..."
  curl "${DEFAULT_CURL_OPTS[@]}" -o "$filename" -C - "$url" || fail "Could not download $url"
}

install_version() {
  local install_type="$1"
  local version="$2"
  local install_path="${3%/bin}/bin"

  if [ "$install_type" != "version" ]; then
    fail "asdf-$TOOL_NAME supports release installs only"
  fi

  (
    mkdir -p "$install_path"
    cp -r "$ASDF_DOWNLOAD_PATH"/* "$install_path"

    # TODO: Assert spark executable exists.
    local tool_cmd
    tool_cmd="$(echo "$TOOL_TEST" | cut -d' ' -f1)"
    test -x "$install_path/$tool_cmd" || fail "Expected $install_path/$tool_cmd to be executable."

    echo "$TOOL_NAME $version installation was successful!"
  ) || (
    rm -rf "$install_path"
    fail "An error occurred while installing $TOOL_NAME $version."
  )
}
