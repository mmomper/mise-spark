#!/usr/bin/env bats
#
# Unit test for lib/utils.bash.

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")" &>/dev/null && pwd)"

load "${CURRENT_DIR}/../lib/utils.bash"
load "${CURRENT_DIR}/resources/spark_archive_mock.bats"

#region list_all_versions
@test "list_all_versions: it should return the correct list-all format from HTML file" {
  result="$(list_all_versions "${CURRENT_DIR}/resources/spark_archive.html")"
  expected_result="0.8.0-incubating 0.9.0-incubating 0.9.2 1.0.0 1.6.3 \
2.0.0-preview 2.0.0 2.4.8 3.0.0-preview 3.0.0-preview2 3.0.0 3.3.0"
  [ "${result}" = "${expected_result}" ]
}

@test "list_all_versions: it should return the correct list-all format from HTML content" {
  result="$(list_all_versions "${spark_archive_html_content_mock:=}")"
  expected_result="3.0.0-preview 3.0.0-preview2 3.0.0 3.3.0"
  [ "${result}" = "${expected_result}" ]
}

@test "list_all_versions: it should return empty string when no archive page is provided" {
  result="$(list_all_versions)"
  [ "${result}" = "" ]
}

@test "list_all_versions: it should return empty string when invalid file path is provided" {
  result="$(list_all_versions 'asdf')"
  [ "${result}" = "" ]
}
#endregion list_all_versions
