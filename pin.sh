#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#参数:title或者alias
pin() {
    #检查参数
    if [[ -z "${1}" ]]; then
        echo "error:the parameter is empty in function:pin"
        exit 1
    fi

    #判断参数是title还是alias
    local title
    local result
    if ! result=$(_input_is_title_or_alias "${1}"); then
        echo "error:the parameter is neither title nor an alias in function:pin"
        exit 1
    fi
    if [[ "${result}" == "title" ]]; then
        title="${1}"
    elif [[ "${result}" == "alias" ]]; then
        if ! title=$(_get_title_by_alias "${1}"); then
            echo "error:get title from alias failed in function:pin"
            exit 1
        fi
    fi

    #目前正在读的书的title
    local title_of_the_reading_book
    title_of_the_reading_book=$(_get_title_of_the_reading_book)

    if [[ -n "${title_of_the_reading_book}" ]]; then
        #是否在重复pin
        if [[ "${title}" == "${title_of_the_reading_book}" ]]; then
            exit 0
        fi

        #将目前正在读的书的状态改为:previous
        _update_field_in_tube_top "${title_of_the_reading_book}" "READING" "previous"
    fi

    #pin
    _update_field_in_tube_top "${title}" "READING" true
}
