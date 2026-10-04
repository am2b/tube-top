#!/usr/bin/env bash

page_up() {
    local adjust_lines_number
    adjust_lines_number=$((SHOW_LINES_NUMBER * 2))

    #注意:不要添加双引号
    jump -${adjust_lines_number}

    print
}
