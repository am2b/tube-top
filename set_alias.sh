#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

set_alias() {
    #检查参数
    if [[ -z "${1}" ]]; then
        echo "error:the parameter is empty in function:set_alias"
        exit 1
    fi

    local alias
    alias="${1}"

    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi

    _update_field_in_tube_top "${title}" "ALIAS" "${alias}"

    exit 0
}
