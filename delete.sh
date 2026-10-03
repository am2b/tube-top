#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

delete_book() {
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

    exit 0
}
