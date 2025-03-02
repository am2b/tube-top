#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

jump() {
    BOOK_NAME=$(_get_the_reading_book_name)
    if [[ -z $BOOK_NAME ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi
    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    _read_record_from_tupe_top

    local number="$1"
    local error_message
    error_message="parameter error, please enter a line number, you can use a positive or negative sign to indicate how many lines to jump back or forward"

    if [[ "$number" =~ ^\+[0-9]+$ ]]; then
        #向后跳
        local number_without_sign
        number_without_sign="${number#[-+]}"
        local cache_down_lines
        cache_down_lines=$((CACHE_TOTAL_LINES - CACHE_CUR_LINE + 1))
        if ((cache_down_lines >= number_without_sign)); then
            CACHE_CUR_LINE=$((CACHE_CUR_LINE + number_without_sign))
            _write_record_to_tupe_top
            return 0
        else
            number=$((CUR_LINE + number_without_sign - cache_down_lines))
        fi
    elif [[ "$number" =~ ^-[0-9]+$ ]]; then
        #向前跳
        local number_without_sign
        number_without_sign="${number#[-+]}"
        local cache_up_lines
        cache_up_lines=$((CACHE_CUR_LINE - 1))
        if ((cache_up_lines >= number_without_sign)); then
            CACHE_CUR_LINE=$((CACHE_CUR_LINE - number_without_sign))
            _write_record_to_tupe_top
            return 0
        else
            number=$((CUR_LINE - CACHE_TOTAL_LINES + cache_up_lines - number_without_sign))
        fi
    fi

    if [[ "$number" =~ ^[0-9]+$ ]]; then
        #跳到实际的行号
        if ((number > TOTAL_LINES)) || ((number <= 0)); then
            echo "${error_message}"
            exit 1
        fi
        if [[ -f "${BOOK_CACHE_FILE}" ]]; then rm "${BOOK_CACHE_FILE}"; fi
        CUR_LINE="${number}"
        CACHE_TOTAL_LINES=0
        CACHE_CUR_LINE=0
        FINISH=false
        _write_record_to_tupe_top
    else
        echo "${error_message}"
        exit 1
    fi
}
