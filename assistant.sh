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
    echo "${script} -p book_name/alias:pin a book"
    #set alias
    echo "${script} -n alias:set an alias"
    #print
    echo "${script} -s:print lines"
    #print again
    echo "${script} -u:print last lines again"
    #jump
    echo "${script} -j line_number:jump to line_number"
    echo "${script} -j +lines:jump backward lines"
    echo "${script} -j -lines:jump forward lines"
    #reset
    echo "${script} -r book_name/alias:reset a book you have read"
    #delete
    echo "${script} -d book_name/alias:delete a book"
    #list
    echo "${script} -l:list all books"

    exit 0
}

parse_options() {
    while getopts ":ha:p:n:sulr:d:j:" opt; do
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
        n)
            set_alias "$OPTARG"
            ;;
        s)
            print
            ;;
        u)
            print_last_again
            ;;
        j)
            jump "$OPTARG"
            ;;
        r)
            reset_book "$OPTARG"
            ;;
        d)
            delete_book "$OPTARG"
            ;;
        l)
            list_all_books
            ;;
        *)
            usage
            ;;
        esac
    done

    shift $((OPTIND - 1))
}
