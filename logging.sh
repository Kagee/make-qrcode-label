#!/usr/bin/env bash
# https://stackoverflow.com/a/48087251
declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)

logThis() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1
    if [ -z "${QK_LOG_LEVEL-}" ]; then
      QK_LOG_LEVEL=DEBUG
    fi
    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$QK_LOG_LEVEL]} )) && return 2

    #log here
    while IFS= read -r message; do
      1>&2 echo "$(date --iso=m) $(basename "$0") [${log_priority}] ${message}"
    done <<< "$log_message"
}
