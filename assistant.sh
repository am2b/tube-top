#!/usr/bin/env bash

script=$(basename "$0")

required_tools() {
    local tools=("sed" "awk")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "$tool 未安装,请安装 GNU Coreutils"
            exit 1
        fi
        if ! "$tool" --version 2>/dev/null | grep -q "GNU"; then
            echo "$tool 不是 GNU Coreutils 版本,请安装正确版本"
            exit 1
        fi
    done
}

usage() {
    echo "usage:"
    echo "${script} -h:show usage"
    #add a book
    echo "${script} -a book_file:add a book"
    #pin a book
    echo "${script} -p book_name:pin a book"
    #print
    echo "${script} -s:print lines"
    #list
    echo "${script} -l:list the books you have read"
    #reset
    echo "${script} -r book_name:reset a book you have read"
    #delete
    echo "${script} -d book_name:delete a book"
    #jump
    echo "${script} -j line_number:jump to line_number"
    echo "${script} -j +lines:jump backward lines"
    echo "${script} -j -lines:jump forward lines"
    exit 0
}

parse_options() {
    while getopts ":ha:p:slr:d:j:" opt; do
        case "${opt}" in
        h)
            usage
            ;;
        a)
            add_book "$OPTARG"
            ;;
        p)
            pin "$OPTARG"
            ;;
        s)
            print
            ;;
        l)
            list_finished_books
            ;;
        r)
            reset_book "$OPTARG"
            ;;
        d)
            delete_book "$OPTARG"
            ;;
        j)
            jump "$OPTARG"
            ;;
        *)
            usage
            ;;
        esac
    done

    shift $((OPTIND - 1))
}
