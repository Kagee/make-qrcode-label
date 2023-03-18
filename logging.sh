#!/usr/bin/env bash
# https://stackoverflow.com/a/48087251
declare -A levels=([DEBUG]=0 [INFO]=1 [WARN]=2 [ERROR]=3)

logThis() {
    local log_message=$1
    local log_priority=$2

    #check if level exists
    [[ ${levels[$log_priority]} ]] || return 1

    #check if level is enough
    (( ${levels[$log_priority]} < ${levels[$script_logging_level]} )) && return 2

    #log here
    echo "$(date --iso=m) $(basename "$0") [${log_priority}] ${log_message}"
}
