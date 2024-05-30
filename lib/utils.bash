#!/usr/bin/env bash
#
# Common utilities for asdf-vm bin commands.

set -euo pipefail

SPARK_ARCHIVE_URL='https://archive.apache.org/dist/spark'
TOOL_NAME='spark'
TOOL_TEST='spark-shell --help'

# shellcheck disable=SC2034
DEFAULT_CURL_OPTS=(-fsSL)
DEFAULT_SPARK_VERSION='3.3.0'
DEFAULT_SHASUM_ALGORITHM=512

echoerr() {
  echo "$1" >&2
}

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
  local custom_hadoop_version="${MISE_TOOL_OPTS__HADOOP_VERSION:-${ASDF_SPARK_HADOOP_VERSION:-}}"
  local without_hadoop="${MISE_TOOL_OPTS__WITHOUT_HADOOP:-${ASDF_SPARK_WITHOUT_HADOOP:-0}}"

  local available_archives available_archives_array without_hadoop_archive_filename \
    with_hadoop_archive_filename available_archives_array_length

  if [[ "${install_type}" != "version" ]]; then
    fail "asdf-$TOOL_NAME only supports version release installation"
  fi

  available_archives="$(scan_available_archives "${spark_version}" "${archive_download_content}")"

  # Get without-hadoop archive filename
  if [[ "${without_hadoop}" =~ ^([yt1]|yes|true)?$ ]]; then
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
# Normalize checksum file content into standard format. Somehow old
# checksum file use invalid checksum file format (not using the
# double-space separated format), so we need to parse and normalize
# the checksum content format.
#
# Arguments:
#   $1 - Checksum file content.
# Outputs:
#   Return double-space separated checksum string,
#   e.g. <hash>  <filename>
##################################################################
normalize_checksum() {
  local checksum_content="${1:-}"

  # Fast return when the checksum content is empty.
  if [[ -z "${checksum_content}" ]]; then
    echo ""
    return
  fi

  # If the content already uses double-space separated format (<hash>  <filename>),
  # then we just return the file content.
  if echo "${checksum_content}" | grep -Eoq '^[A-Fa-f0-9]+  spark\-(.+)\.tgz$'; then
    echo "${checksum_content}"
  # If the content is still using the old checksum format (<filename>: <hash>),
  # then we need to parse the checksum and construct it into
  # double-space separated format.
  elif echo "${checksum_content}" | grep -Eoq '^spark\-(.+)\: [A-Fa-f0-9 ]+$'; then
    echo "${checksum_content}" |
      # Trim all whitespace and newline, also transform to lowercase.
      tr -d ' \n' | tr '[:upper:]' '[:lower:]' | xargs |
      # Construct the double-space separated format.
      sed -E 's/^(spark\-.+\.tgz)\:([a-f0-9]+)$/\2  \1/g'
  else
    fail "Checksum content is invalid. Can not parse the hash value."
  fi
}

##################################################################
# Download and normalize the sha checksum value.
#
# Arguments:
#   $1 - Apache download URL.
#   $2 - Archive filepath.
# Outputs:
#   Return a valid checksum value format separated by double space,
#   e.g. <hash>  <filename>
##################################################################
download_sha_checksum() {
  local archive_download_url="${1:-}"
  local archive_filepath="${2:-}"
  local archive_filename="${archive_filepath##*/}"
  # Some old spark archives use .sha extension instead of .sha512.
  local checksum_exts=('sha512' 'sha')
  local checksum_content normalized_checksum_content

  for ext in "${checksum_exts[@]}"; do
    if checksum_content="$(curl "${DEFAULT_CURL_OPTS[@]}" "${archive_download_url}.${ext}")"; then
      break
    fi
  done

  # Fail-fast if checksum_content is still empty (no checksum available).
  if [[ -z "${checksum_content}" ]]; then
    rm "${archive_filepath}"
    fail "Can't verify archive checksum. If this error persist, then you can set ASDF_SPARK_SKIP_VERIFICATION \
value to true to skip this verification step."
  fi

  # Normalize downloaded checksum file content.
  normalized_checksum_content="$(normalize_checksum "${checksum_content}")"
  echo "${normalized_checksum_content}"
}

##################################################################
# Verify Apache Spark binary archive file checksum using
# sha-512 algorithm.
#
# Globals:
#   ASDF_SPARK_SKIP_VERIFICATION - Skip checksum verification or not.
# Arguments:
#   $1 - Archive download URL.
#   $2 - Archive filepath.
# Outputs:
#   Return exit status code 0 when the target file checksum matches
#   the hash from the checksum content.
##################################################################
verify_sha_checksum() {
  local archive_download_url="${1:-}"
  local archive_filepath="${2:-}"
  local archive_filename="${archive_filepath##*/}"
  local skip_verification="${MISE_TOOL_OPTS__SKIP_VERIFICATION:-${ASDF_SPARK_SKIP_VERIFICATION:-0}}"
  local checksum

  # Fast return if ASDF_SPARK_SKIP_VERIFICATION is set to true.
  if [[ "${skip_verification}" =~ ^([yt1]|yes|true)?$ ]]; then
    echo "* Skip checksum verification as your request..."
    return
  fi

  # cd into ASDF_DOWNLOAD_PATH
  cd "$(dirname "${archive_filepath}")"

  echo "* Verifying ${archive_filename}..."
  checksum="$(download_sha_checksum "${archive_download_url}" "${archive_filepath}")"
  if ! echo "${checksum}" | shasum --algorithm "${DEFAULT_SHASUM_ALGORITHM}" --check; then
    rm "${archive_filepath}"
    fail "Checksum validation failed! Abort installation."
  fi
}

write_pom() {
  local spark_version=$1

  cat >pom.xml <<EOL
<project xmlns="http://maven.apache.org/POM/4.0.0"
         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                             http://maven.apache.org/maven-v4_0_0.xsd">
    <modelVersion>4.0.0</modelVersion>
    <groupId>org.sonatype.mavenbook.simple</groupId>
    <artifactId>simple</artifactId>
    <packaging>jar</packaging>
    <version>1.0-SNAPSHOT</version>
    <name>simple</name>
    <url>http://maven.apache.org</url>
    <dependencies>
        <dependency>
            <groupId>org.apache.spark</groupId>
            <artifactId>spark-hadoop-cloud_2.12</artifactId>
            <version>$spark_version</version>
        </dependency>
    </dependencies>
</project>
EOL

}

download_cloud_jars() {
  local download_path=$1
  local spark_version=$2

  echo "downloading jars"

  if ! command -v mvn &>/dev/null; then
    echoerr maven is missing.
    return 1
  fi

  write_pom $spark_version

  mvn dependency:copy-dependencies -DoutputDirectory=$download_path/jars

  rm -rf pom.xml
}

##################################################################
# Download Apache Spark prebuilt binary archive into provided
# ASDF_DOWNLOAD_PATH.
#
# Arguments:
#   $1 - asdf install type.
#   $2 - asdf download path.
#   $3 - Apache Spark version.
# Outputs:
#   Exit code 0 if successfully downloading the archive file, else
#   1 with error message.
##################################################################
download_archive() {
  local install_type="${1:-}"
  local download_path="${2:-}"
  local spark_version="${3:-}"

  local with_cloud_jars="${MISE_TOOL_OPTS__WITH_CLOUD_JARS:-${ASDF_SPARK_WITH_CLOUD_JARS:-0}}"
  # Apache Spark specific version archive homepage, e.g. https://archive.apache.org/dist/spark/spark-3.3.1
  local spark_archives_url="${SPARK_ARCHIVE_URL}/spark-${spark_version}"

  local spark_archive_download_page_content spark_archive_filename spark_archive_filepath spark_archive_download_url

  # Find the correct Apache Spark version from the archive homepage.
  spark_archive_download_page_content="$(curl "${DEFAULT_CURL_OPTS[@]}" "${spark_archives_url}")"
  spark_archive_filename="$(
    get_release_archive_filename "${install_type}" "${spark_version}" "${spark_archive_download_page_content}"
  )"
  spark_archive_filepath="${download_path}/${spark_archive_filename}"
  # Apache Spark archive download URL, e.g. https://archive.apache.org/dist/spark/spark-3.3.1/spark-3.3.1-bin-hadoop3.tgz
  spark_archive_download_url="$(construct_release_archive_url "${spark_version}" "${spark_archive_filename}")"

  echo "* Downloading ${spark_archive_filename}..."
  curl -fSL# -o "${spark_archive_filepath}" -C - "${spark_archive_download_url}" || fail "Could not download ${spark_archive_download_url}"

  verify_sha_checksum "${spark_archive_download_url}" "${spark_archive_filepath}"

  #  Extract contents of tar.gz file into the download directory.
  tar -xzf "${spark_archive_filepath}" -C "${download_path}" --strip-components=1 || fail "Could not extract ${spark_archive_filepath}"

  if [[ "${with_cloud_jars}" =~ ^([yt1]|yes|true)?$ ]]; then
    download_cloud_jars $download_path $spark_version
  fi

  # Remove the tar.gz file since we don't need to keep it.
  rm "${spark_archive_filepath}"
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

  local without_hadoop="${MISE_TOOL_OPTS__WITHOUT_HADOOP:-${ASDF_SPARK_WITHOUT_HADOOP:-0}}"

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

    if [[ "${without_hadoop}" =~ ^([yt1]|yes|true)?$ ]]; then
      echo "hadoop_classpath=\$(hadoop classpath)" >>"$install_path/conf/spark-env.sh"
    fi
  ) || (
    rm -rf "${install_path}"
    fail "An error occurred while installing ${TOOL_NAME}-${version}."
  )
}
