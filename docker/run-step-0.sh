#!/bin/bash

export LC_ALL="C"
set -euo pipefail
cd "$(dirname "$0")"

# would use -u "$(id -u):$(id -g)" but the container can't be readonly and files inside are root-owned
exec docker run -it --rm --tmpfs /.cache --tmpfs /run --tmpfs /tmp 'localhost/hamronization_workflow-step-0' "${@:-bash}"
