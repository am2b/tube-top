#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

search() {
    local pattern
    pattern="${1}"

    BOOK_NAME=$(_get_the_reading_book_name)
    if [[ -z $BOOK_NAME ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi

    BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top

    if [[ "${FINISH}" == true ]]; then
        echo "You have finished the book:${BOOK_NAME}"
        echo "You can reset the book:tube_top.sh -r ${BOOK_NAME}"
        exit 0
    fi

    #已读行的下一行
    local search_from_line_number
    search_from_line_number=$((CUR_LINE - 1 - CACHE_TOTAL_LINES + CACHE_CUR_LINE))
    #jump存在删除BOOK_CACHE_FILE的可能
    #if [[ ! -f "${CACHE_DIR}"/"${BOOK_NAME}" ]]; then
    #    search_from_line_number="${CUR_LINE}"
    #fi

    declare -A matched_lines
    local plain_line_num

    while IFS=: read -r line_num content; do
        plain_line_num=$(echo "$line_num" | sed 's/\x1B\[[0-9;]*m//g')
        #如果要计算实际的行号的话:
        #real_line=$((plain_line_num + search_from_line_number - 1))
        trimmed_content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        matched_lines["$plain_line_num"]="$trimmed_content"
    done < <(tail -n +"${search_from_line_number}" "${BOOK_FILE}" | rg --color=always --line-number "${pattern}" | head -n 5)

    local array_size
    array_size="${#matched_lines[@]}"
    local counter=0
    for origin_relative_line_num in $(printf "%s\n" "${!matched_lines[@]}" | sort -n); do
        ((counter++))
        #减1:是因为做了jump +num后,然后print的时候是从下一行开始print的
        jump_line_num=$((origin_relative_line_num - 1))
        #强迫症:按照show_lines_number的整数倍去跳转
        #jump_line_num=$((jump_line_num / show_lines_number * show_lines_number))
        #第一列:绿色的:line_num(%-6s:左对齐,宽度为6)
        #第二列:蓝色的:->
        #第三列:黄色的:do jump(%-7s:左对齐,宽度为7)
        #第四列:黄色的:+line_num
        #printf "\033[32m%-6s\033[0m \033[34m->\033[0m \033[33m%-7s +%s\033[0m\n" "$origin_relative_line_num" "do a jump" "$jump_line_num"
        printf "\033[32m+%-6s\033[0m" "$jump_line_num"
        echo -e "${matched_lines["$origin_relative_line_num"]}"
        if [[ "${counter}" -lt "${array_size}" ]]; then echo; fi
    done

    exit 0
}
