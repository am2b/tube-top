#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

page_up() {
    local adjust_lines_number
    adjust_lines_number=$((show_lines_number * 2))

    #注意:不要添加双引号
    jump -${adjust_lines_number}

    print
}
