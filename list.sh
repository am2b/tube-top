#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

list_all_books() {
    local percent
    local cur_real_line_num
    BOOK_NAME=$(_get_the_reading_book_name)

    if [[ -n "${BOOK_NAME}" ]]; then
        _read_record_from_tupe_top
        cur_real_line_num=$((CUR_LINE - 1 - CACHE_TOTAL_LINES + CACHE_CUR_LINE - 1))
        #如果一行都没有读的话
        if [[ "${CUR_LINE}" -eq 1 ]]; then cur_real_line_num=0; fi
        percent=$(echo "scale=10; $cur_real_line_num / $TOTAL_LINES * 100" | bc)
        #这种方法会丢掉0.70前面的0
        #percent=$(echo "scale=2; $percent/1" | bc)
        percent=$(printf "%.2f" "$percent")
    fi

    local book_name_field_num
    local alias_field_num
    local reading_field_num
    local finish_field_num

    book_name_field_num=$(_get_field_num "BOOK_NAME")
    alias_field_num=$(_get_field_num "ALIAS")
    reading_field_num=$(_get_field_num "READING")
    finish_field_num=$(_get_field_num "FINISH")

    local color_alias="\033[38;5;24m"
    local color_arrow="\033[33m"
    local color_previous_reading="\033[38;5;22m"
    local color_reading="\033[32m"
    local color_finish="\033[90m"
    local color_percent="\033[34m"
    local color_reset="\033[0m"

    awk -F, -v book_name_field="$book_name_field_num" -v alias_field="$alias_field_num" \
        -v reading_field="$reading_field_num" -v finish_field="$finish_field_num" \
        -v percent="$percent" \
        -v color_alias="$color_alias" \
        -v color_arrow="$color_arrow" \
        -v color_previous_reading="$color_previous_reading" \
        -v color_reading="$color_reading" \
        -v color_finish="$color_finish" \
        -v color_percent="$color_percent" \
        -v color_reset="$color_reset" \
        'BEGIN {OFS=","}
{
    output = "["color_alias $(alias_field) color_reset"] " $(book_name_field);
    if ($reading_field == "true" && $finish_field == "true") {
        output = output color_arrow " <- " color_reading "reading" color_reset " - " color_finish "finish" color_reset;
    }else if ($reading_field == "previous" && $finish_field == "true") {
        output = output color_arrow " <- " color_previous_reading "previous reading" color_reset " - " color_finish "finish" color_reset;
    } else if ($reading_field == "true") {
        output = output color_arrow " <- " color_reading "reading" color_reset "[" color_percent percent "%" color_reset "]";
    } else if ($reading_field == "previous") {
        output = output color_arrow " <- " color_previous_reading "previous reading" color_reset;
    } else if ($finish_field == "true") {
        output = output color_arrow " <- " color_finish "finish" color_reset;
    }
    print output;
}' "${TUBE_TOP}"

    #仅查询,无需写入记录
    exit 0
}
