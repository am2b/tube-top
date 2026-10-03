#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#参数:title或者alias
reset_book() {
    if [[ -z "${1}" ]]; then
        echo "error:the parameter is empty in function:reset_book"
    fi

    #判断参数是title还是alias
    local title
    local result
    if ! result=$(_input_is_title_or_alias "${1}"); then
        echo "error:the parameter is neither title nor an alias in function:reset_book"
        exit 1
    fi
    if [[ "${result}" == "title" ]]; then
        title="${1}"
    elif [[ "${result}" == "alias" ]]; then
        if ! title=$(_get_title_by_alias "${1}"); then
            echo "error:get title from alias failed in function:reset_book"
            exit 1
        fi
    fi

    local cache_file
    cache_file="${CACHE_DIR}"/"${title}"
    if [[ -f "${cache_file}" ]]; then rm "${cache_file}"; fi

    _update_field_in_tube_top "${title}" "READING" false
    _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" 1
    _update_field_in_tube_top "${title}" "CACHE_TOTAL_LINES" 0
    _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" 1
    _update_field_in_tube_top "${title}" "FINISH" false
}
