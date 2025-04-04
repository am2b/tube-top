#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

_do_print() {
    local cache_left_lines
    cache_left_lines=$((CACHE_TOTAL_LINES - CACHE_CUR_LINE + 1))

    local show_lines_real_number
    if [[ "${cache_left_lines}" -lt "${show_lines_number}" ]]; then
        show_lines_real_number="${cache_left_lines}"
    else
        show_lines_real_number="${show_lines_number}"
    fi

    if [[ "${show_lines_real_number}" -ne 0 ]]; then
        #without line number
        #tail -n +"${CACHE_CUR_LINE}" "${BOOK_CACHE_FILE}" | head -n "${show_lines_real_number}"
        #with line number
        #nl -v$((CUR_LINE - CACHE_TOTAL_LINES)) "${BOOK_CACHE_FILE}" | tail -n +"${CACHE_CUR_LINE}" | head -n "${show_lines_real_number}"
        #with line number
        #awk -v start="$CACHE_CUR_LINE" -v number="$show_lines_real_number" -v origin_current_line="$CUR_LINE" -v cache_total_lines="$CACHE_TOTAL_LINES" 'NR>=start && NR<(start + number) {print (origin_current_line - cache_total_lines - 1 + NR), $0}' "${BOOK_CACHE_FILE}"
        #with color
        mapfile -t colors <"${COLORS_FILE}"
        local colors_size="${#colors[@]}"
        local color_index_file=/tmp/tube_top_color_index
        local color_index
        local selected_color
        if [[ ! -f "${color_index_file}" ]]; then
            echo 0 >"${color_index_file}"
        fi
        color_index=$(cat "${color_index_file}")
        local next_color_index=$((color_index + 1))
        if ((next_color_index == colors_size)); then
            rm "${color_index_file}"
        else
            echo "${next_color_index}" >"${color_index_file}"
        fi
        selected_color=${colors[$color_index]}

        #行号颜色
        local line_number_color="\033[90m"
        #如果当前文本的颜色和行号的颜色相同时
        if [[ "${line_number_color}" == "${selected_color}" ]]; then
            #临时修改一下行号的颜色
            line_number_color="\033[38;5;24m"
        fi

        local reset_color="\033[0m"

        awk -v start="$CACHE_CUR_LINE" \
            -v number="$show_lines_real_number" \
            -v origin_current_line="$CUR_LINE" \
            -v cache_total_lines="$CACHE_TOTAL_LINES" \
            -v selected_color="$selected_color" \
            -v line_number_color="$line_number_color" \
            -v reset_color="$reset_color" \
            -v enable_line_number="$enable_line_number" \
            -v enable_color="$enable_color" \
            '
            NR >= start && NR < (start + number) {
                #是否打印行号
                if (enable_line_number == 1) {
                    if (enable_color == 1) {
                        printf "%s[%d]%s ", line_number_color, (origin_current_line - cache_total_lines - 1 + NR), reset_color
                    }
                    else {
                        printf "[%d] ", (origin_current_line - cache_total_lines - 1 + NR)
                    }
                }

                #打印内容部分
                if (enable_color == 1) {
                    printf "%s%s%s\n", selected_color, $0, reset_color
                }
                else {
                    printf "%s\n", $0
                }
            }' "${BOOK_CACHE_FILE}"

        #update current cache line
        CACHE_CUR_LINE=$((CACHE_CUR_LINE + show_lines_real_number))
    fi
}

print() {
    BOOK_NAME=$(_get_the_reading_book_name)
    if [[ -z $BOOK_NAME ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi

    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"
    BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top

    if [[ "${FINISH}" == true ]]; then
        echo "You have finished the book:${BOOK_NAME}"
        echo "You can reset the book:tube_top.sh -r ${BOOK_NAME}"
        exit 0
    fi

    local book
    if ! book=$(_query_book_in_tube_top); then
        echo "error:the book:${BOOK_NAME} was not found in ${TUBE_TOP}"
        exit 1
    fi

    #需要做cache的3中情形:
    #1,还没有cache
    #2,cache被完美消耗完了
    #3,cache无法被完美消耗完,剩下的行数小于show_lines_number

    #刚开始读该书(还没有cache)
    if [[ ! -f "${BOOK_CACHE_FILE}" ]]; then
        #echo "cache 1"
        _cache
    else
        #cache的行数是show_lines_number的整数倍
        if ((CACHE_CUR_LINE > CACHE_TOTAL_LINES)); then
            #echo "cache 2"
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
                    #echo "cache 3"
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

    _write_record_to_tupe_top
}

print_last_again() {
    jump_to_last

    print
}
