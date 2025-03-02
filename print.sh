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
        colors=(
            "\033[31m"       # 红色
            "\033[32m"       # 绿色
            "\033[33m"       # 黄色
            "\033[34m"       # 蓝色
            "\033[35m"       # 紫色
            "\033[36m"       # 青色
            "\033[91m"       # 浅红色
            "\033[92m"       # 浅绿色
            "\033[93m"       # 浅黄色
            "\033[94m"       # 浅蓝色
            "\033[95m"       # 浅紫色
            "\033[96m"       # 浅青色
            "\033[37m"       # 白色
            "\033[90m"       # 灰色
            "\033[97m"       # 亮白色
            "\033[38;5;208m" # 橙色
            "\033[38;5;172m" # 棕色
            "\033[38;5;130m" # 深橙色
            "\033[38;5;82m"  # 浅绿蓝色
            "\033[38;5;46m"  # 鲜艳绿色
        )

        local rand_index=$((RANDOM % ${#colors[@]}))
        local selected_color=${colors[$rand_index]}

        #行号颜色(默认绿色)
        local line_number_color="\033[32m"

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
                        printf "%s%d%s ", line_number_color, (origin_current_line - cache_total_lines - 1 + NR), reset_color
                    }
                    else {
                        printf "%d ", (origin_current_line - cache_total_lines - 1 + NR)
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
    local adjust_lines_number
    adjust_lines_number=$((show_lines_number))

    #注意:不要添加双引号
    jump -${adjust_lines_number} && _write_record_to_tupe_top

    print
}
