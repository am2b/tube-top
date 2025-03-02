#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

#列出已经读完的书
list_all_books() {
    book_name_field_num=$(_get_field_num "BOOK_NAME")
    alias_field_num=$(_get_field_num "ALIAS")
    reading_field_num=$(_get_field_num "READING")
    finish_field_num=$(_get_field_num "FINISH")

    awk -F, -v book_name="$book_name_field_num" -v alias_name="$alias_field_num" -v reading="$reading_field_num" -v finish="$finish_field_num" '{
        output = "["$alias_name"]" " "$book_name;
        if ($reading == "true" && $finish == "true") {
            output = output " <- reading - finish";
        } else if ($reading == "true") {
            output = output " <- reading";
        } else if ($finish == "true") {
            output = output " <- finish";
        }
        print output;
    }' "${TUBE_TOP}"

    #仅查询,无需写入记录
    exit 0
}
