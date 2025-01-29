#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/assistant.sh
source "${SELF_ABS_DIR}"/impl.sh
source "${SELF_ABS_DIR}"/do_print.sh

add_book() {
    local origin_file="${1}"

    if [[ ! -f $origin_file ]]; then
        echo "$origin_file is not a normal file"
        exit 1
    fi

    if ! file "${origin_file}" | grep -q "text"; then
        echo "$origin_file is not a text file"
        exit 1
    fi

    if [[ ! -r $origin_file ]]; then
        echo "$origin_file is unreadable"
        exit 1
    fi

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

print() {
    BOOK_NAME="${1}"
    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"
    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    _read_record_from_tupe_top

    if [[ "${FINISH}" == true ]]; then
        echo "You have finished the book:${BOOK_NAME}"
        echo "You can reset the book:tube_top.sh -r ${BOOK_NAME}"
        exit 0
    fi

    if ! book=$(_query_book_in_tube_top); then
        echo "error:the book:${BOOK_NAME} was not found in ${TUBE_TOP}"
        exit 1
    fi

    local last_reading_book_name
    last_reading_book_name=$(_query_the_reading_book_in_tube_top)
    if [[ "${BOOK_NAME}" != "${last_reading_book_name}" ]]; then
        #change the reading status of other books to false
        #-E:启用扩展正则表达式(ERE),使正则表达式语法更简洁(无需转义括号()等)
        #([^,]*,):
        #([^,]*,):匹配非逗号的任意字符([^,],非逗号),后跟一个逗号(,)
        #[^,]*:匹配接下来的字段(直到下一个逗号或行尾)
        #\1false:
        #\1:表示正则表达式中第一个捕获组([^,]*,),即匹配的第一个字段加逗号
        #false:将第二字段替换为false
        sed -i -E 's/^(([^,]*,))[^,]*/\1false/' "${TUBE_TOP}"

        #set the reading status of this book to true
        READING=true
    fi

    #需要做cache的3中情形:
    #1,还没有cache
    #2,cache被完美消耗完了
    #3,cache无法被完美消耗完,剩下的行数小于show_lines_number

    #刚开始读该书(还没有cache)
    if [[ ! -f "${BOOK_CACHE_FILE}" ]]; then
        echo "cache 1"
        _cache
    else
        #cache的行数是show_lines_number的整数倍
        if ((CACHE_CUR_LINE > CACHE_TOTAL_LINES)); then
            echo "cache 2"
            _cache
        else
            #需要回退(剩下的行数小于show_lines_number)
            local cache_left_lines
            cache_left_lines=$((CACHE_TOTAL_LINES - CACHE_CUR_LINE + 1))
            if ((cache_left_lines < show_lines_number)); then
                #原始文件里是否还有剩余的行数来支持回退
                local origin_left_lines
                origin_left_lines=$((TOTAL_LINES - CUR_LINE + 1))
                if ((origin_left_lines > 0)); then
                    CUR_LINE=$((CUR_LINE - cache_left_lines))
                    echo "cache 3"
                    _cache
                fi
            fi
        fi
    fi

    _do_print

    #update the finish flag
    if [[ "${CUR_LINE}" -gt "${TOTAL_LINES}" && "${CACHE_CUR_LINE}" -gt "${CACHE_TOTAL_LINES}" ]]; then
        FINISH=true
        echo "You have finished the book:${BOOK_NAME}"
    fi

    return 0
}

#列出已经读完的书
list_finished_books() {
    #表示finish的true或false位于第7列
    sed -n '/^\([^,]*,\)\{6\}true/p' "${TUBE_TOP}" | cut -d',' -f1
}

#重置一本已经读完的书(使其处于未读的状态)
reset_book() {
    BOOK_NAME="${1}"

    READING=false
    CUR_LINE=1
    CACHE_TOTAL_LINES=0
    CACHE_CUR_LINE=0
    FINISH=false

    rm "${BOOK_CACHE_FILE}"
}

main() {
    required_tools

    _tube_top_init

    _read_config

    parse_options "${@}"

    _write_record_to_tupe_top
}

main "${@}"
