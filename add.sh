#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#参数:原始文件的路径
add_book() {
    #检查参数
    if [[ -z "${1}" ]]; then
        echo "error:the parameter is empty in function:add_book"
        exit 1
    fi

    local origin_file="${1}"

    if [[ ! -f $origin_file ]]; then
        echo "$origin_file is not a normal file in function:add_book"
        exit 1
    fi

    if [[ ! -r $origin_file ]]; then
        echo "$origin_file is unreadable in function:add_book"
        exit 1
    fi

    local title
    local book_file
    #title中包含后缀名(basename的结果包含后缀名)
    title=$(basename "${origin_file}")
    #数据库中的原始文件
    book_file="${BOOKS_DIR}"/"${title}"

    #检查数据库中是否已经有了要添加的书
    if [[ -f "${book_file}" ]] || _get_record "${title}"; then
        echo "error:the library already contains a book with the same title:${title} in function:add_book"
        exit 1
    fi

    #save this book to the library
    cp "${origin_file}" "${book_file}"

    #register this book
    local original_total_lines
    original_total_lines=$(wc -l < "${book_file}" | xargs)

    #如果传递了"别名"作为第二个参数的话
    local alias_name="none"
    if [[ -n "${2}" ]]; then
        alias_name="${2}"
    fi

    #do cache
    #_cache "${BOOK_NAME}"

    #_write_record_to_tupe_top
    local reading original_next_line cache_total_lines cache_next_line finish ever_finished
    reading=false
    original_next_line=1
    cache_total_lines=0
    cache_next_line=0
    finish=false
    echo "${title}","${alias_name}","${reading}","${original_total_lines}","${original_next_line}","${cache_total_lines}","${cache_next_line}","${finish}","${ever_finished}" >> "${TUBE_TOP}"

    exit 0
}
