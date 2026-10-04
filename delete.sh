#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

delete_book() {
    check_parameters 1 -- "$@" || exit $?

    #判断参数是title还是alias
    local title
    title=$(_get_title_from_input "${1}")

    local book_file cache_file
    book_file="${BOOKS_DIR}"/"${title}"
    cache_file="${CACHE_DIR}"/"${title}"
    if [[ -f "${cache_file}" ]]; then rm "${cache_file}"; fi
    if [[ -f "${book_file}" ]]; then rm "${book_file}"; fi

    #删除record
    sed -i "/^$title/d" "${TUBE_TOP}"

    #删除完成后,检查是否存在reading的书
    local title_reading
    title_reading=$(_get_title_of_the_reading_book)
    if [[ -z "${title_reading}" ]]; then
        #再检查是否有previous,如果有的话,将其设置为reading
        local title_previous
        title_previous=$(_get_title_of_the_previous)
        if [[ -n "${title_previous}" ]]; then
            pin "${title_previous}"
        fi
    fi
}
