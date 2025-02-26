#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

delete_book() {
    BOOK_NAME="${1}"

    if ! _query_book_in_tube_top > /dev/null; then
        echo "the book name:${BOOK_NAME} is invalid"
        exit 1
    fi

    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"
    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    if [[ -f "${BOOK_CACHE_FILE}" ]]; then rm "${BOOK_CACHE_FILE}"; fi
    if [[ -f "${BOOK_FILE}" ]]; then rm "${BOOK_FILE}"; fi

    _delete_book_from_tube_top

    #避免再次将记录写入
    exit 0
}
