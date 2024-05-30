#!/usr/bin/env bats
#
# Unit test for lib/utils.bash.

set -euo pipefail

UTIL_TEST_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")" &>/dev/null && pwd)"

load "${UTIL_TEST_DIR}/../lib/utils.bash"
load "${UTIL_TEST_DIR}/resources/mock_wrapper.bash"

# Override DEFAULT_SPARK_VERSION variable for testing purpose
DEFAULT_SPARK_VERSION='3.3.0'

#region fail
@test "fail: it should show an error message with exit status code 1" {
  local error_message='Lorem ipsum dolor sip amet'
  run fail "${error_message}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: ${error_message}" ]
}

@test "fail: it should show an error message from multiple arguments with exit status code 1" {
  local error_message='Lorem ipsum dolor sip amet'
  local error_message_2='My time has come'
  run fail "${error_message}" "${error_message_2}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: ${error_message} ${error_message_2}" ]
}
#endregion fail

#region list_all_versions
@test "list_all_versions: it should return the correct list-all format from HTML content" {
  run list_all_versions "${spark_archive_html_content_mock:-}"
  expected_result="0.8.0-incubating
0.9.0-incubating
0.9.2
1.0.0
1.6.3
2.0.0-preview
2.0.0
2.4.8
3.0.0-preview
3.0.0-preview2
3.0.0
3.3.0"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${expected_result}" ]
}

@test "list_all_versions: it should return empty string when no archive HTML content is provided" {
  run list_all_versions
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}

@test "list_all_versions: it should return empty string when no version is matched from the HTML content" {
  run list_all_versions 'Lorem ipsum sip dolor amet'
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
#endregion list_all_versions

#region scan_available_archives
@test "scan_available_archives: it should return all available spark binary archives from the dist HTML content" {
  run scan_available_archives "3.3.0" "${spark_330_download_html_content_mock:-}"
  expected_result="spark-3.3.0-bin-hadoop2.tgz
spark-3.3.0-bin-hadoop3-scala2.13.tgz
spark-3.3.0-bin-hadoop3.tgz
spark-3.3.0-bin-without-hadoop.tgz"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${expected_result}" ]
}

@test "scan_available_archives: it should use DEFAULT_SPARK_VERSION when no spark version is specified" {
  run scan_available_archives "" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ -n "${output}" ]
}

@test "scan_available_archives: it should return empty string when no available spark binary archives is available" {
  run scan_available_archives "3.4.0" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
#endregion scan_available_archives

#region construct_release_archive_url
@test "construct_release_archive_url: it should return a valid prebuilt binary download URL" {
  local archive_filename='example.tgz'
  run construct_release_archive_url "${DEFAULT_SPARK_VERSION}" "${archive_filename}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${SPARK_ARCHIVE_URL}/spark-${DEFAULT_SPARK_VERSION}/${archive_filename}" ]
}

@test "construct_release_archive_url: it should show an error message when no spark version is specified" {
  local archive_filename='example.tgz'
  run construct_release_archive_url "" "${archive_filename}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Apache Spark version is required." ]
}

@test "construct_release_archive_url: it should show an error message when no archive filename is specified" {
  run construct_release_archive_url "${DEFAULT_SPARK_VERSION}" ""
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Spark binary archive filename is required." ]
}
#endregion construct_release_archive_url

#region get_release_archive_filename
@test "get_release_archive_filename: it should return the latest hadoop version URL (ASDF_SPARK_HADOOP_VERSION is not set)" {
  run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]
}

@test "get_release_archive_filename: it should return the latest hadoop version URL (ASDF_SPARK_HADOOP_VERSION is not set with explicit ASDF_SPARK_WITHOUT_HADOOP)" {
  # Explicitly set the ASDF_SPARK_WITHOUT_HADOOP env variable.
  ASDF_SPARK_WITHOUT_HADOOP=no run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=n run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=false run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=f run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=0 run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop3.tgz" ]
}

@test "get_release_archive_filename: it should return the latest hadoop version URL (ASDF_SPARK_HADOOP_VERSION is set)" {
  ASDF_SPARK_HADOOP_VERSION=2 run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-hadoop2.tgz" ]
}

@test "get_release_archive_filename: it should return error message when the install type is not version based" {
  run get_release_archive_filename "ref" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: asdf-spark only supports version release installation" ]
}

@test "get_release_archive_filename: it should return error message when no any prebuilt binary archive available" {
  run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_111_broken_download_html_content_mock:-}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Unfortunately, current Apache Spark version does not provide hadoop support prebuilt binary archive." ]
}

@test "get_release_archive_filename: it should return error message when the custom hadoop version is not available" {
  ASDF_SPARK_HADOOP_VERSION='2.3' run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Unfortunately, Apache Spark with Hadoop 2.3 is not available yet." ]
}

@test "get_release_archive_filename: it should return without hadoop version URL when ASDF_SPARK_WITHOUT_HADOOP is set" {
  ASDF_SPARK_WITHOUT_HADOOP=1 run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-without-hadoop.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=y run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-without-hadoop.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=yes run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-without-hadoop.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=t run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-without-hadoop.tgz" ]

  ASDF_SPARK_WITHOUT_HADOOP=true run get_release_archive_filename "version" "${DEFAULT_SPARK_VERSION}" "${spark_330_download_html_content_mock:-}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "spark-${DEFAULT_SPARK_VERSION}-bin-without-hadoop.tgz" ]
}

@test "get_release_archive_filename: it should return error message when there is no without-hadoop version available" {
  local spark_version='1.1.1'
  ASDF_SPARK_WITHOUT_HADOOP=1 run get_release_archive_filename "version" "1.1.1" "${spark_111_download_html_content_mock:-}"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Apache Spark ${spark_version} does not have without-hadoop archive." ]
}
#endregion get_release_archive_filename

#region normalize_checksum
@test "normalize_checksum: it should get the hash value from the checksum file with colon separated (legacy checksum file)" {
  run normalize_checksum "${spark_111_sha512_content:-}"
  local expected_result="77e186130a40886eb7a0a5b434e63dd98b0689d4db873f32fcac3866d41928\
05a4702fe578894bff31792aa135b2adb899224c38ebe03cf6a53a62a1f6fe3230  spark-1.1.1.tgz"
  echo "${output}"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${expected_result}" ]
}

@test "normalize_checksum: it should get the hash value from the checksum file with double space separated" {
  run normalize_checksum "${spark_303_sha512_content:-}"
  local expected_result="72abf6a414f9a3216537ee0da463baba52f966ded645fd8621c4b77e76249e\
75075ff9e45d2e4f9c80b22dcb90d4c78518a3fceaf6c03deb00f6c444ebf9618a  spark-3.0.3.tgz"
  [ "${status}" -eq 0 ]
  [ "${output}" = "${expected_result}" ]
}

@test "normalize_checksum: it should return an error message when no valid hash value is found" {
  run normalize_checksum "Lalalalalalala:NaNaNaNaNa NaNaNa"
  [ "${status}" -eq 1 ]
  [ "${output}" = "asdf-spark: Checksum content is invalid. Can not parse the hash value." ]
}
#endregion normalize_checksum
