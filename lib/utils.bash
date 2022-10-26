#!/usr/bin/env bash
#
# Common utilities for asdf-vm bin commands.

set -euo pipefail

GH_REPO="https://github.com/apache/spark"
SPARK_ARCHIVE_URL='https://archive.apache.org/dist/spark'
TOOL_NAME='spark'
TOOL_TEST='spark-shell --help'

DEFAULT_CURL_OPTS=(-fsSL)
DEFAULT_SPARK_VERSION='3.3.0'

##################################################
# Print error message with generalized format.
#
# Arguments:
#   $* - Error message
# Outputs:
#   A defined error message text with exit code 1.
##################################################
fail() {
  echo -e "asdf-${TOOL_NAME}: $*"
  exit 1
}

#################################################
# List all available Apache Spark versions.
#
# Arguments:
#   $1 - Apache spark archive HTML content.
# Outputs:
#   All available version with newline delimited.
#################################################
list_all_versions() {
  local archive_src="${1:-}"

  if [[ -z "${archive_src}" ]]; then
    echo ""
    return
  fi

  { grep -Eo '<a href="spark-[0-9]+\.[0-9]+\.[0-9]+(\-[a-z0-9]+)?\/">' <<<"${archive_src}" || :; } |
    sed -E 's/^<a href="spark-(.+)\/">$/\1/g'
}

######################################################
# Scan available spark pre-built binaries archives.
#
# Arguments:
#   $1 - Apache Spark version.
#   $2 - Spark archive HTML page content.
# Outputs:
#   All available spark archives separated by newline.
######################################################
scan_available_archives() {
  local spark_version="${1:-"${DEFAULT_SPARK_VERSION}"}"
  local html_content="${2:-}"

  if [[ -z "${html_content}" ]]; then
    echo ""
    return
  fi

  { grep -Eo "<a href=\"spark-${spark_version}-bin-(.+)\.tgz\">" <<<"${html_content}" || :; } |
    sed -E 's/^<a href="(.+)">$/\1/g'
}

##############################################################
# Construct Apache Spark prebuilt binary archive download URL.
#
# Arguments:
#   $1 - Apache Spark version.
#   $2 - Archive filename.
# Outputs:
#   A valid apache spark prebuilt binary archive download URL.
##############################################################
construct_release_archive_url() {
  local spark_version="${1:-}"
  local archive_filename="${2:-}"

  if [[ -z "${spark_version}" ]]; then
    fail "Apache Spark version is required."
  fi

  if [[ -z "${archive_filename}" ]]; then
    fail "Spark binary archive filename is required."
  fi

  echo "${SPARK_ARCHIVE_URL}/spark-${spark_version}/${archive_filename}"
}

##################################################################
# Get Apache Spark prebuilt binary archive filename based on
# the specified environment variable (if any).
#
# Globals:
#   ASDF_SPARK_HADOOP_VERSION - Custom hadoop version for current
#                               Apache Spark version.
#   ASDF_SPARK_WITHOUT_HADOOP - Prefer archive without hadoop support?
# Arguments:
#   $1 - Apache Spark version.
#   $2 - Archive filename.
# Outputs:
#   A valid apache spark prebuilt binary archive download URL.
##################################################################
get_release_archive_filename() {
  local install_type="${1:-'version'}"
  local spark_version="${2:-"${DEFAULT_SPARK_VERSION}"}"
  local archive_download_content="${3:-}"
  local custom_hadoop_version="${ASDF_SPARK_HADOOP_VERSION:-}"
  local without_hadoop="${ASDF_SPARK_WITHOUT_HADOOP:-0}"

  local available_archives available_archives_array without_hadoop_archive_filename \
    with_hadoop_archive_filename available_archives_array_length

  if [[ "${install_type}" != "version" ]]; then
    fail "asdf-$TOOL_NAME only supports version release installation"
  fi

  available_archives="$(scan_available_archives "${spark_version}" "${archive_download_content}")"

  # Get without-hadoop archive filename
  if [[ ! "${without_hadoop}" =~ [0|f|false] ]]; then
    without_hadoop_archive_filename="$({ grep "spark-${spark_version}-bin-without-hadoop\.tgz" <<<"${available_archives}" || :; } | xargs)"
    if [[ -n "${without_hadoop_archive_filename}" ]]; then
      echo "${without_hadoop_archive_filename}"
      return
    else
      fail "Apache Spark ${spark_version} does not have without-hadoop archive."
    fi
  fi

  # Get custom hadoop version when users provide it.
  if [[ -n "${custom_hadoop_version}" ]]; then
    with_hadoop_archive_filename="$(
      { grep -o "spark-${spark_version}-bin-hadoop${custom_hadoop_version}\.tgz" <<<"${available_archives}" || :; } | xargs
    )"
    if [[ -n "${with_hadoop_archive_filename}" ]]; then
      echo "${with_hadoop_archive_filename}"
      return
    else
      fail "Unfortunately, Apache Spark with Hadoop ${custom_hadoop_version} is not available yet."
    fi
  fi

  # Get the latest hadoop version when users do not provide it.
  with_hadoop_archive_filename="$(
    { grep -Eo "spark-${spark_version}-bin-hadoop[0-9](\.[0-9])?\.tgz" <<<"${available_archives}" || :; } | xargs
  )"
  read -r -a available_archives_array <<<"${with_hadoop_archive_filename}"

  available_archives_array_length="${#available_archives_array[@]}"
  if [[ "${available_archives_array_length}" -gt "0" ]]; then
    echo "${available_archives_array[$((available_archives_array_length - 1))]}"
  else
    fail "Unfortunately, current Apache Spark version does not provide hadoop support prebuilt binary archive."
  fi
}

##################################################################
# Download Apache Spark prebuilt binary archive into provided
# ASDF_DOWNLOAD_PATH.
#
# Arguments:
#   $1 - Apache spark archive download URL.
#   $2 - Apache spark archive target path.
# Outputs:
#   Exit code 0 if successfully downloading the archive file, else
#   1 with error message.
##################################################################
download_archive() {
  local download_url="${1:-}"
  local target_filepath="${2:-}"

  echo "* Downloading ${target_filepath##*/}..."
  curl -fSL# -o "${target_filepath}" -C - "${download_url}" || fail "Could not download ${download_url}"
}

##################################################################
# Extract and install Apache Spark prebuilt binary archive into
#  provided asdf install path.
#
# Arguments:
#   $1 - asdf install type.
#   $2 - Apache Spark version.
#   $3 - asdf install path.
# Outputs:
#   Exit code 0 if successfully installing the archive file, else
#   1 with error message.
##################################################################
install_version() {
  local install_type="${1:-}"
  local version="${2:-}"
  local install_path="${3:-}"

  local tool_cmd

  if [[ "${install_type}" != "version" ]]; then
    fail "asdf-$TOOL_NAME only supports version release installation"
  fi

  (
    mkdir -p "${install_path}"
    cp -r "${ASDF_DOWNLOAD_PATH}"/* "${install_path}"

    tool_cmd="$(echo "${TOOL_TEST}" | cut -d' ' -f1)"
    [[ -x "${install_path}/bin/${tool_cmd}" ]] || fail "Expected ${install_path}/bin/${tool_cmd} to be executable."

    echo "${TOOL_NAME}-${version} installation was successful!"
  ) || (
    rm -rf "${install_path}"
    fail "An error occurred while installing ${TOOL_NAME}-${version}."
  )
}
