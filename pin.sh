#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

pin() {
    _set_BOOK_NAME_by_parameter "${1}"

    local last_reading_book_name
    last_reading_book_name=$(_get_the_reading_book_name)

    if [[ -n "${last_reading_book_name}" ]] && [[ "${BOOK_NAME}" == "${last_reading_book_name}" ]]; then
        exit 0
    fi

    #change the reading status of all books to false
    _update_field_of_all_records_in_tube_top "READING" false

    local hold_book_name
    if [[ -n "${last_reading_book_name}" ]]; then
        hold_book_name="${BOOK_NAME}"
        BOOK_NAME="${last_reading_book_name}"
        _update_field_in_tube_top "READING" last
        BOOK_NAME="${hold_book_name}"
    fi

    _update_field_in_tube_top "READING" true
}
