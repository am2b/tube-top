#!/usr/bin/env bash

sort_lines_by_alias() {
    check_parameters 1 -- "$@" || return $?

    local sorted_tube_top="${1}"
    local none_records=/tmp/none_records
    local sorted_records=/tmp/sorted_records

    # 先分离出所有第二列为'none'的记录
    awk -F, '$2 == "none" {print $0}' "$TUBE_TOP" > "${none_records}"

    # 再将其他记录进行排序
    awk -F, '$2 != "none" {print $0}' "$TUBE_TOP" | sort -t, -k2,2 > "${sorted_records}"

    # 将排序后的记录与'none'记录合并,'none'记录放在后面
    #-s:文件存在,并且非空
    if [[ -s "${none_records}" ]]; then
        cat "${sorted_records}" "${none_records}" > "${sorted_tube_top}"
    else
        mv "${sorted_records}" "${sorted_tube_top}"
    fi

    rm -f "${none_records}" "${sorted_records}"
}

list_all_books() {
    #依据alias排序
    local sorted_tube_top=/tmp/sorted_tube_top
    if ! sort_lines_by_alias "${sorted_tube_top}"; then
        echo "error:sort lines by alias failed in function:list_all_books" >&2
        exit 1
    fi

    local title
    #title可以为空
    title=$(_get_title_of_the_reading_book)

    #当前实际已经阅读了的行数
    local cur_real_line_num
    local percent=""

    if [[ -n "${title}" ]]; then
        local record
        if ! record=$(_get_record "${title}"); then
            echo "error:get record of title:${title} failed in function:_do_print" >&2
            exit 1
        fi

        local original_total_lines original_next_line
        original_total_lines=$(_get_original_total_lines_of_record "${record}")
        original_next_line=$(_get_original_next_line_of_record "${record}")

        local cache_total_lines cache_next_line
        cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
        cache_next_line=$(_get_cache_next_line_of_record "${record}")

        cur_real_line_num=$((original_next_line - 1 - cache_total_lines + cache_next_line - 1))
        #如果一行都没有读的话
        if [[ "${original_next_line}" -eq 1 ]]; then cur_real_line_num=0; fi
        percent=$(echo "scale=10; $cur_real_line_num / $original_total_lines * 100" | bc)
        #这种方法会丢掉0.70前面的0
        #percent=$(echo "scale=2; $percent/1" | bc)
        percent=$(printf "%.2f" "$percent")
    fi

    local title_field_num
    local alias_field_num
    local reading_field_num
    local ever_finished_field_num

    title_field_num=$(_get_field_num "TITLE")
    alias_field_num=$(_get_field_num "ALIAS")
    reading_field_num=$(_get_field_num "READING")
    ever_finished_field_num=$(_get_field_num "EVER_FINISHED")

    local color_alias="\033[38;5;58m"
    local color_title="\033[38;5;24m"
    local color_arrow="\033[33m"
    local color_previous_reading="\033[38;5;22m"
    local color_reading="\033[32m"
    local color_ever_finished="\033[90m"
    local color_percent="\033[34m"
    local color_reset="\033[0m"

    awk -F, -v title_field="$title_field_num" -v alias_field="$alias_field_num" \
        -v reading_field="$reading_field_num" -v ever_finished_field="$ever_finished_field_num" \
        -v percent="$percent" \
        -v color_alias="$color_alias" \
        -v color_title="$color_title" \
        -v color_arrow="$color_arrow" \
        -v color_previous_reading="$color_previous_reading" \
        -v color_reading="$color_reading" \
        -v color_ever_finished="$color_ever_finished" \
        -v color_percent="$color_percent" \
        -v color_reset="$color_reset" \
        'BEGIN {OFS=","}
{
    output = color_alias "["$(alias_field)"] " color_title $(title_field) color_reset;
    if ($reading_field == "true" && $ever_finished_field == "true") {
        output = output color_arrow " <- " color_reading "reading" color_reset " - " color_ever_finished "finish" color_reset;
    }else if ($reading_field == "previous" && $ever_finished_field == "true") {
        output = output color_arrow " <- " color_previous_reading "previous reading" color_reset " - " color_ever_finished "finish" color_reset;
    } else if ($reading_field == "true") {
        output = output color_arrow " <- " color_reading "reading" color_reset "[" color_percent percent "%" color_reset "]";
    } else if ($reading_field == "previous") {
        output = output color_arrow " <- " color_previous_reading "previous reading" color_reset;
    } else if ($ever_finished_field == "true") {
        output = output color_arrow " <- " color_ever_finished "finish" color_reset;
    }
    print output;
}' "${sorted_tube_top}"

    rm "${sorted_tube_top}"
}
