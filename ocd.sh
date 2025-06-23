#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

ocd() {
    BOOK_NAME=$(_get_the_reading_book_name)
    if [[ -z $BOOK_NAME ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi

    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    _read_record_from_tupe_top

    local next_line
    next_line=$((CUR_LINE - CACHE_TOTAL_LINES + CACHE_CUR_LINE - 1))
    #整数除法自动向下取整
    local batch_num=$(((next_line - 1) / 10))
    #第n批次所对应的行号:n * 10 + 1 ~ (n + 1) * 10
    CUR_LINE=$((batch_num * 10 + 1))

    if [[ -f "${BOOK_CACHE_FILE}" ]]; then rm "${BOOK_CACHE_FILE}"; fi
    _cache

    _write_record_to_tupe_top
    exit 0
}

#Obsessive-Compulsive Disorder(强迫症)
