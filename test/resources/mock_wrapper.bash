#!/usr/bin/env bash

set -euo pipefail

SPARK_ARCHIVE_MOCK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# shellcheck disable=SC2034
spark_archive_html_content_mock="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark_archive.html")"

# shellcheck disable=SC2034
spark_330_download_html_content_mock="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark_3.3.0_archive_download.html")"

# shellcheck disable=SC2034
spark_111_download_html_content_mock="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark_1.1.1_archive_download.html")"

# shellcheck disable=SC2034
spark_111_broken_download_html_content_mock="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark_1.1.1_broken_archive_download.html")"

# shellcheck disable=SC2034
spark_111_sha512_content="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark-1.1.1.tgz.sha")"

# shellcheck disable=SC2034
spark_303_sha512_content="$(cat "${SPARK_ARCHIVE_MOCK_DIR}/spark-3.0.3.tgz.sha512")"
