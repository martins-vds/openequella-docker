#!/bin/bash
set -euo pipefail

source ./equellaserver-config.sh
# The installer emits a multiline list of JVM flags, not shell commands.
read -r -a jvm_options <<< "${JAVA_OPTS//$'\n'/ }"
exec java "${jvm_options[@]}" -Xmx1024m -cp "$CLASSPATH" \
    com.tle.core.equella.runner.EQUELLAServer
