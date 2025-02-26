#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#重置一本已经读完的书(使其处于未读的状态)
reset_book() {
    BOOK_NAME="${1}"

    if ! _query_book_in_tube_top > /dev/null; then
        echo "the book name:${BOOK_NAME} is invalid"
        exit 1
    fi

    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top

    READING=false
    CUR_LINE=1
    CACHE_TOTAL_LINES=0
    CACHE_CUR_LINE=0
    FINISH=false

    if [[ -f "${BOOK_CACHE_FILE}" ]]; then rm "${BOOK_CACHE_FILE}"; fi
}
