#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#参数:title或者alias
pin() {
    check_parameters 1 -- "$@" || exit $?

    #判断参数是title还是alias
    local title
    if ! title=$(_get_title_from_input "${1}"); then exit 1; fi

    #目前正在读的书的title
    local title_of_the_reading_book
    if ! title_of_the_reading_book=$(_get_title_of_the_reading_book); then
        echo "error:get title failed in function:pin"
        exit 1
    fi

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
