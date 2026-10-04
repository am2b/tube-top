#!/usr/bin/env bash

#没有参数
_do_print() {
    local record title
    if ! record=$(_get_record_of_the_reading_book); then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi
    title=$(_get_title_of_record "${record}")

    local original_total_lines original_next_line
    original_total_lines=$(_get_original_total_lines_of_record "${record}")
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    local cache_left_lines
    cache_left_lines=$((cache_total_lines - cache_next_line + 1))

    local show_lines_real_number
    if [[ "${cache_left_lines}" -lt "${SHOW_LINES_NUMBER}" ]]; then
        show_lines_real_number="${cache_left_lines}"
    else
        show_lines_real_number="${SHOW_LINES_NUMBER}"
    fi

    local cache_file
    cache_file="${CACHE_DIR}"/"${title}"

    if [[ "${show_lines_real_number}" -ne 0 ]]; then
        #without line number
        #tail -n +"${cache_next_line}" "${cache_file}" | head -n "${show_lines_real_number}"
        #with line number
        #nl -v$((original_next_line - cache_total_lines)) "${cache_file}" | tail -n +"${cache_next_line}" | head -n "${show_lines_real_number}"
        #with line number
        #awk -v start="$cache_next_line" -v number="$show_lines_real_number" -v origin_current_line="$original_next_line" -v cache_total_lines="$cache_total_lines" 'NR>=start && NR<(start + number) {print (origin_current_line - cache_total_lines - 1 + NR), $0}' "${cache_file}"
        #with color
        mapfile -t colors < "${COLORS_FILE}"
        local colors_size="${#colors[@]}"
        local color_index_file=/tmp/tube_top_color_index
        local color_index
        local selected_color
        if [[ ! -f "${color_index_file}" ]]; then
            echo 0 > "${color_index_file}"
        fi
        color_index=$(cat "${color_index_file}")
        local next_color_index=$((color_index + 1))
        if ((next_color_index == colors_size)); then
            rm "${color_index_file}"
        else
            echo "${next_color_index}" > "${color_index_file}"
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

        awk -v start="$cache_next_line" \
            -v number="$show_lines_real_number" \
            -v origin_current_line="$original_next_line" \
            -v cache_total_lines="$cache_total_lines" \
            -v selected_color="$selected_color" \
            -v line_number_color="$line_number_color" \
            -v reset_color="$reset_color" \
            -v enable_line_number="$ENABLE_LINE_NUMBER" \
            -v enable_color="$ENABLE_COLOR" \
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
            }' "${cache_file}"

        cache_next_line=$((cache_next_line + show_lines_real_number))
        _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" "${cache_next_line}"
    fi
}

#没有参数
print() {
    local record title
    if ! record=$(_get_record_of_the_reading_book); then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi
    title=$(_get_title_of_record "${record}")

    local finish
    finish=$(_get_finish_of_record "${record}")
    if [[ "${finish}" == true ]]; then
        echo "You have finished the book:${title}"
        echo "You can reset the book:tube_top.sh -r ${title}"
        exit 0
    fi

    _cache

    _do_print

    #再次读取record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:print"
        exit 1
    fi

    #检查是否读完了
    local original_total_lines original_next_line
    original_total_lines=$(_get_original_total_lines_of_record "${record}")
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    if [[ "${original_next_line}" -gt "${original_total_lines}" && "${cache_next_line}" -gt "${cache_total_lines}" ]]; then
        _update_field_in_tube_top "${title}" "FINISH" true
        _update_field_in_tube_top "${title}" "EVER_FINISHED" true

        echo "You have finished the book:${title}"
    fi
}

#没有参数
print_last_again() {
    jump_to_last

    print
}
