#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

list_all_books() {
    local percent
    local cur_real_line_num
    BOOK_NAME=$(_get_the_reading_book_name)
    _read_record_from_tupe_top
    cur_real_line_num=$((CUR_LINE - 1 - CACHE_TOTAL_LINES + CACHE_CUR_LINE - 1))
    percent=$(echo "scale=10; $cur_real_line_num / $TOTAL_LINES * 100" | bc)
    #这种方法会丢掉0.70前面的0
    #percent=$(echo "scale=2; $percent/1" | bc)
    percent=$(printf "%.2f" "$percent")

    local book_name_field_num
    local alias_field_num
    local reading_field_num
    local finish_field_num

    book_name_field_num=$(_get_field_num "BOOK_NAME")
    alias_field_num=$(_get_field_num "ALIAS")
    reading_field_num=$(_get_field_num "READING")
    finish_field_num=$(_get_field_num "FINISH")

    awk -F, -v book_name_field="$book_name_field_num" -v alias_field="$alias_field_num" \
        -v reading_field="$reading_field_num" -v finish_field="$finish_field_num" \
        -v percent="$percent" 'BEGIN {OFS=","} 
{
    output = "["$(alias_field)"]" " "$(book_name_field);
    if ($reading_field == "true" && $finish_field == "true") {
        output = output " <- reading - finish";
    }else if ($reading_field == "previous" && $finish_field == "true") {
        output = output " <- previous reading - finish";
    } else if ($reading_field == "true") {
        output = output " <- reading""["percent"%]";
    } else if ($reading_field == "previous") {
        output = output " <- previous reading";
    } else if ($finish_field == "true") {
        output = output " <- finish";
    }
    print output;
}' "${TUBE_TOP}"

    #仅查询,无需写入记录
    exit 0
}
