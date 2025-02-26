#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

#列出已经读完的书
list_all_books() {
    awk -F, '{
    output = $1;
    if ($3 == "true" && $8 == "true") {
        output = output " <- reading - finish";
    } else if ($3 == "true") {
        output = output " <- reading";
    } else if ($8 == "true") {
        output = output " <- finish";
    }
    print output;
}' "${TUBE_TOP}"

    #仅查询,无需写入记录
    exit 0
}
