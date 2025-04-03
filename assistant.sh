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

    tools=("trash")
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "$tool 未安装"
            exit 1
        fi
    done
}

usage() {
    echo "usage:"
    echo "${script} -h:show usage"
    #add a book
    echo "${script} -a book_file:add a book"
    #add a book and set alias
    echo "${script} -a book_file alias_name:add a book and set alias"
    #pin a book
    echo "${script} -p book_name/alias:pin a book(note:pin for the first time,need book_name)"
    #set alias
    echo "${script} -n alias:set an alias"
    #quickly switch
    echo "${script} -q:quickly switch to the previous book"
    #print
    echo "${script} -s:print lines"
    #print again
    echo "${script} -g:print last lines again"
    #page up
    echo "${script} -u:page up"
    #jump
    echo "${script} -j line_number:jump to line_number"
    echo "${script} -j +lines:jump backward lines"
    echo "${script} -j -lines:jump forward lines"
    echo "${script} -j 0:jump back"
    echo "${script} -j e:jump to the end"
    #search pattern(search from the current line)
    echo "${script} -f pattern:search pattern(search from the current line)"
    #reset
    echo "${script} -r book_name/alias:reset a book you have read"
    #delete
    echo "${script} -d book_name/alias:delete a book"
    #list
    echo "${script} -l:list all books"
    #backup
    echo "${script} -b:backup database file:tube_top"

    exit 0
}

parse_options() {
    while getopts ":ha:p:n:qsguj:f:r:d:lb" opt; do
        case "${opt}" in
        h)
            usage
            ;;
        a)
            #${!OPTIND}使用了间接引用(indirect reference)来获取OPTIND指向的变量的值
            if [ -n "${!OPTIND}" ]; then
                add_book "$OPTARG" "${!OPTIND}"
                #更新OPTIND,让它指向下一个未被解析的命令行参数
                OPTIND=$((OPTIND + 1))
            else
                add_book "$OPTARG"
            fi
            ;;
        p)
            pin "$OPTARG"
            ;;
        n)
            set_alias "$OPTARG"
            ;;
        q)
            quickly_switch
            ;;
        s)
            print
            ;;
        g)
            print_last_again
            ;;
        u)
            page_up
            ;;
        j)
            jump "$OPTARG"
            ;;
        f)
            search "$OPTARG"
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
        b)
            backup
            ;;
        *)
            usage
            ;;
        esac
    done

    #getopts每个选项默认只能携带一个参数

    #OPTARG是当前选项的参数,也就是说,如果你执行-a foo,那么OPTARG就是foo
    #OPTIND表示下一个未被解析的命令行位置参数的索引
    #每次调用getopts后,OPTIND的值会自动更新,直到所有选项处理完毕‌

    #移除已处理的选项参数,使$1指向剩余的第一个位置参数
    shift $((OPTIND - 1))
}
