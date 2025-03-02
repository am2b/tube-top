#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#列出已经读完的书
list_all_books() {
    local book_name_field_num
    local alias_field_num
    local reading_field_num
    local finish_field_num

    book_name_field_num=$(_get_field_num "BOOK_NAME")
    alias_field_num=$(_get_field_num "ALIAS")
    reading_field_num=$(_get_field_num "READING")
    finish_field_num=$(_get_field_num "FINISH")

    awk -F, -v book_name_field="$book_name_field_num" -v alias_field="$alias_field_num" \
        -v reading_field="$reading_field_num" -v finish_field="$finish_field_num" 'BEGIN {OFS=","} 
{
    output = "["$(alias_field)"]" " "$(book_name_field);
    if ($(reading_field) == "true" && $(finish_field) == "true") {
        output = output " <- reading - finish";
    }else if ($(reading_field) == "previous" && $(finish_field) == "true") {
        output = output " <- previous reading - finish";
    } else if ($(reading_field) == "true") {
        output = output " <- reading";
    } else if ($(reading_field) == "previous") {
        output = output " <- previous reading";
    } else if ($(finish_field) == "true") {
        output = output " <- finish";
    }
    print output;
}' "${TUBE_TOP}"

    #仅查询,无需写入记录
    exit 0
}
