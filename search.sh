#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

search() {
    if [[ -z "${1}" ]]; then
        echo "error:the parameter is empty in function:search"
    fi

    local pattern
    pattern="${1}"

    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:jump"
        exit 1
    fi

    local finish
    finish=$(_get_finish_of_record "${record}")
    if [[ "${finish}" == true ]]; then
        echo "You have finished the book:${title}"
        echo "You can reset the book:tube_top.sh -r ${title}"
        exit 0
    fi

    local original_next_line
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    #已读行的下一行
    local search_from_line_number
    search_from_line_number=$((original_next_line - 1 - cache_total_lines + cache_next_line))

    book_file="${BOOKS_DIR}"/"${title}"

    declare -A matched_lines
    local plain_line_num

    while IFS=: read -r line_num content; do
        plain_line_num=$(echo "$line_num" | sed 's/\x1B\[[0-9;]*m//g')
        #如果要计算实际的行号的话:
        #real_line=$((plain_line_num + search_from_line_number - 1))
        trimmed_content=$(echo "$content" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        matched_lines["$plain_line_num"]="$trimmed_content"
    done < <(tail -n +"${search_from_line_number}" "${book_file}" | rg --color=always --line-number "${pattern}" | head -n 5)

    local array_size
    array_size="${#matched_lines[@]}"
    local counter=0
    for origin_relative_line_num in $(printf "%s\n" "${!matched_lines[@]}" | sort -n); do
        ((counter++))
        #减1:是因为做了jump +num后,然后print的时候是从下一行开始print的
        jump_line_num=$((origin_relative_line_num - 1))
        #强迫症:按照SHOW_LINES_NUMBER的整数倍去跳转
        #jump_line_num=$((jump_line_num / SHOW_LINES_NUMBER * SHOW_LINES_NUMBER))
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
