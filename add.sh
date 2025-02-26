#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

add_book() {
    local origin_file="${1}"

    if [[ ! -f $origin_file ]]; then
        echo "$origin_file is not a normal file"
        exit 1
    fi

    #if ! file "${origin_file}" | grep -q "text"; then
    #    echo "$origin_file is not a text file"
    #    exit 1
    #fi

    if [[ ! -r $origin_file ]]; then
        echo "$origin_file is unreadable"
        exit 1
    fi

    #BOOK_NAME中包含后缀名(basename的结果包含后缀名)
    BOOK_NAME=$(basename "${origin_file}")
    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"

    #check if the library already has this book
    if [[ -f "${BOOK_FILE}" ]] || _query_book_in_tube_top; then
        echo "error:the library already contains a book with the same name:${BOOK_NAME}"
        exit 1
    fi

    #save this book to the library
    cp "${origin_file}" "${BOOK_FILE}"

    #register this book
    READING=false
    TOTAL_LINES=$(wc -l <"${BOOK_FILE}" | xargs)
    CUR_LINE=1
    CACHE_TOTAL_LINES=0
    CACHE_CUR_LINE=0
    FINISH=false

    echo "${BOOK_NAME}","${READING}","${TOTAL_LINES}","${CUR_LINE}","${CACHE_TOTAL_LINES}","${CACHE_CUR_LINE}","${FINISH}" >>"${TUBE_TOP}"

    return 0
}
