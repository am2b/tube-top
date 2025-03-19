#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

delete_book() {
    _set_BOOK_NAME_by_parameter "${1}"

    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"
    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    if [[ -f "${BOOK_CACHE_FILE}" ]]; then rm "${BOOK_CACHE_FILE}"; fi
    if [[ -f "${BOOK_FILE}" ]]; then rm "${BOOK_FILE}"; fi

    _delete_book_from_tube_top

    #删除完成后,检查是否存在reading的书
    local reading_book_name
    reading_book_name=$(_get_the_reading_book_name)
    if [[ -z "${reading_book_name}" ]]; then
        #再检查是否有previous,如果有的话,将其设置为reading
        local previous_book_name
        previous_book_name=$(_get_the_previous_reading_book_name)
        if [[ -n "${previous_book_name}" ]]; then
            pin "${previous_book_name}"
        fi
    fi

    exit 0
}
