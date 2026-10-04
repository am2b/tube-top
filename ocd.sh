#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

ocd() {
    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    local record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:_do_print"
        exit 1
    fi

    local original_next_line
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    local next_line
    next_line=$((original_next_line - cache_total_lines + cache_next_line - 1))
    #整数除法自动向下取整
    local batch_num=$(((next_line - 1) / 10))
    #第n批次所对应的行号:n * 10 + 1 ~ (n + 1) * 10
    original_next_line=$((batch_num * 10 + 1))
    _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"

    _delete_cache_file "${title}"

    exit 0
}

#Obsessive-Compulsive Disorder(强迫症)
