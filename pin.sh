#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

pin() {
    BOOK_NAME="${1}"

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top

    local book
    local last_reading_book_name
    #该函数返回的是一个完整的record
    if book=$(_query_the_reading_book_in_tube_top); then
        IFS=',' read -r -a parts <<<"${book}"
        last_reading_book_name="${parts[0]}"
        if [[ "${BOOK_NAME}" != "${last_reading_book_name}" ]]; then
            #change the reading status of all books to false

            #-E:启用扩展正则表达式(ERE),使正则表达式语法更简洁(无需转义括号()等)
            #([^,]*,):
            #([^,]*,):匹配非逗号的任意字符([^,],非逗号),后跟一个逗号(,)
            #[^,]*:匹配接下来的字段(直到下一个逗号或行尾)
            #\1false:
            #\1:表示正则表达式中第一个捕获组([^,]*,),即匹配的第一个字段加逗号
            #false:将第二字段替换为false
            sed -i -E 's/^(([^,]*,))[^,]*/\1false/' "${TUBE_TOP}"
        fi
    fi

    #set the reading status of this book to true
    READING=true
}
