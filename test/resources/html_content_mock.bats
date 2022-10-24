#!/usr/bin/env bats

set -euo pipefail

# shellcheck disable=SC2034
html_content_mock="$(
  cat <<'MOCK'
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 3.2 Final//EN">
<html>
 <head>
  <title>Index of /dist/spark</title>
 </head>
 <body>
<h1>Index of /dist/spark</h1>
<pre><img src="/icons/blank.gif" alt="Icon "> <a href="?C=N;O=D">Name</a>                    <a href="?C=M;O=A">Last modified</a>      <a href="?C=S;O=A">Size</a>  <a href="?C=D;O=A">Description</a><hr><img src="/icons/back.gif" alt="[PARENTDIR]"> <a href="/dist/">Parent Directory</a>                             -
<img src="/icons/folder.gif" alt="[DIR]"> <a href="spark-3.0.0-preview/">spark-3.0.0-preview/</a>    2019-11-06 23:15    -
<img src="/icons/folder.gif" alt="[DIR]"> <a href="spark-3.0.0-preview2/">spark-3.0.0-preview2/</a>   2019-12-22 18:53    -
<img src="/icons/folder.gif" alt="[DIR]"> <a href="spark-3.0.0/">spark-3.0.0/</a>            2020-06-16 09:19    -
<img src="/icons/folder.gif" alt="[DIR]"> <a href="spark-3.3.0/">spark-3.3.0/</a>            2022-06-17 11:11    -
<img src="/icons/unknown.gif" alt="[   ]"> <a href="KEYS">KEYS</a>                    2022-06-15 08:08  102K
<hr></pre>
</body></html>
MOCK
)"
