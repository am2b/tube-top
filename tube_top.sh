#!/usr/bin/env bash

script=$(basename "$0")

#dirs:
root_dir="${HOME}"/.tube-top
books_dir="${root_dir}"/books
cache_dir="${root_dir}"/cache

#records of books
tube_top="${root_dir}"/tube_top

cache_lines_number=10
show_lines_number=3

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
    echo "${script} -i book_file:add a book"
    #read a book
    echo "${script} -s book_name:read a book"

    echo "${script} -j line_number:jump to line_number"
    echo "${script} -j +lines:jump backward lines"
    echo "${script} -j -lines:jump forward lines"

    echo "${script} -d book_name:delete a book"
    echo "${script} -l:list the books you have read"
    echo "${script} -c:clear all settings and caches"
    exit 0
}

parse_options() {
    while getopts ":hi:s:j:d:lc" opt; do
        #while getopts ":hi:j:d:lc" opt; do
        case "${opt}" in
        h)
            usage
            ;;
        i)
            add_book "$OPTARG"
            ;;
        s)
            print "$OPTARG"
            ;;
        j)
            jump_to_line "$OPTARG"
            ;;
        d)
            delete_book "$OPTARG"
            ;;
        l)
            list_books
            ;;
        c)
            clear
            ;;
        *)
            usage
            ;;
        esac
    done

    shift $((OPTIND - 1))
}

_init() {
    if [[ ! -d $root_dir ]]; then mkdir -p "${root_dir}"; fi
    if [[ ! -d $books_dir ]]; then mkdir -p "${books_dir}"; fi
    if [[ ! -d $cache_dir ]]; then mkdir -p "${cache_dir}"; fi

    touch "${tube_top}"
    #echo "cache_lines_number=10" >>config
    #echo "show_lines_number=3" >>config
    #echo "color=green" >>config
}

_save_book_file() {
    local book_file
    book_file="${1}"
    local book_name
    book_name=$(basename "$book_file")

    #check if the library already has this book
    if _get_book_file "${book_name}" || _query_book_in_tube_top "${book_name}"; then
        echo "error:the library already contains a book with the same name:${book_name}"
        exit 1
    fi

    #save this book to the library
    cp "${book_file}" "${books_dir}"
}

_get_book_file() {
    local book_name="${1}"
    local book_file="${books_dir}"/"${book_name}"
    if [[ -f $book_file ]]; then
        echo "${book_file}"
        return 0
    else
        return 1
    fi
}

_get_book_cache_file() {
    local book_name="${1}"
    local book_cache_file="${cache_dir}"/"${book_name}"
    if [[ -f $book_cache_file ]]; then
        echo "${book_cache_file}"
        return 0
    else
        return 1
    fi
}

_get_tube_top_file() {
    if [[ -f "${tube_top}" ]]; then
        echo "${tube_top}"
        return 0
    else
        return 1
    fi
}

_query_book_in_tube_top() {
    local book_name="${1}"
    local result
    result=$(sed -n "/^$book_name,/p" "${tube_top}")
    if [[ -n $result ]]; then
        echo "${result}"
        return 0
    else
        return 1
    fi
}

_query_the_reading_book_in_tube_top() {
    local result
    #表示reading的true或false位于第2列
    #\([^,]*,\):匹配一个组,即非逗号的字符([^,])的0或多个重复,紧跟一个逗号(,)
    result=$(sed -n '/^\([^,]*,\)true,/p' "${tube_top}")
    if [[ -n $result ]]; then
        echo "${result}"
        return 0
    else
        return 1
    fi
}

#列出已经读完的书
_list_the_finished_book_in_tube_top() {
    local result
    #表示finish的true或false位于第7列
    sed -n '/^\([^,]*,\)\{6\}true,/p' "${tube_top}"
}

_add_book_in_tube_top() {
    local book_name="${1}"
    local reading="${2}"
    local total_lines="${3}"
    local current_line="${4}"
    local total_cache_lines="${5}"
    local current_cache_line="${6}"
    local finish="${7}"
    if ! book=$(_query_book_in_tube_top "${book_name}"); then
        echo "${book_name}","${reading}","${total_lines}","${current_line}","${total_cache_lines}","${current_cache_line}","${finish}" >>"${tube_top}"
    else
        echo "error:the book:${book_name} was found,when adding in ${tube_top}"
        exit 1
    fi
}

_delete_book_from_tube_top() {
    local book_name="${1}"
    if ! book=$(_query_book_in_tube_top "${book_name}"); then
        echo "error:the book:${book_name} was not found,when deleting in ${tube_top}"
    else
        sed -i "/^$book_name,/d" "${tube_top}"
    fi
}

_update_book_in_tube_top() {
    local book_name="${1}"
    local modify_column="${2}"
    local new_value="${3}"

    if book=$(_query_book_in_tube_top "${book_name}"); then
        IFS=',' read -r -a parts <<<"${book}"

        #check if $modify_column is valid
        if ((modify_column <= 0)) || ((modify_column > ${#parts[@]})); then
            echo "error:invalid column:${modify_column}"
            exit 1
        fi

        #modify
        local index=$((modify_column - 1))
        parts[index]="${new_value}"

        #concatenate arrays using commas
        updated_book=$(
            IFS=','
            echo "${parts[*]}"
        )

        #delete book from tube top
        _delete_book_from_tube_top "${book_name}"

        #append book to tube top
        echo "${updated_book}" >>"${tube_top}"
    else
        echo "error:the book:${book_name} was not found,when updating in ${tube_top}"
        exit 1
    fi
}

_cache() {
    local book_name="${1}"
    local book_file
    local book_cache_file="${cache_dir}"/"${book_name}"

    if book=$(_query_book_in_tube_top "${book_name}"); then
        IFS=',' read -r -a parts <<<"${book}"
        local total_lines="${parts[2]}"
        local current_line="${parts[3]}"

        local cache_lines_count
        #check if current_line+cache_lines_number exceeds the total lines
        if ((current_line + cache_lines_number - 1 > total_lines)); then
            cache_lines_count=$((total_lines - current_line + 1))
        else
            cache_lines_count="${cache_lines_number}"
        fi

        if ! book_file=$(_get_book_file "${book_name}"); then
            echo "error:the book file:${book_file} was not found in ${books_dir} when caching"
            exit 1
        fi

        awk "NR>=${current_line} && NR<${current_line}+${cache_lines_count}" "${book_file}" >"${book_cache_file}"

        #update total cache lines and current cache line
        local total_cache_lines
        total_cache_lines=$(wc -l <"${book_cache_file}" | xargs)
        _update_book_in_tube_top "${book_name}" 5 "${total_cache_lines}"
        _update_book_in_tube_top "${book_name}" 6 1

        #update current line in the entire book
        _update_book_in_tube_top "${book_name}" 4 $((current_line + cache_lines_count))
    else
        echo "error:the book:${book_name} was not found in ${tube_top} when caching"
        exit 1
    fi
}

add_book() {
    if (($# != 1)); then
        echo "init a book to read from the beginning:"
        echo "$script -i book_file"
        exit 1
    fi

    local book_file="${1}"

    if [[ ! -f $book_file ]]; then
        echo "$book_file is not a normal file"
        exit 1
    fi

    if ! file "${book_file}" | grep -q "text"; then
        echo "$book_file is not a text file"
        exit 1
    fi

    if [[ ! -r $book_file ]]; then
        echo "$book_file is unreadable"
        exit 1
    fi

    if [[ ! -f "${tube_top}" ]]; then
        _init
    fi

    _save_book_file "${book_file}"

    #register this book
    local book_name
    book_name=$(basename "$book_file")
    local reading=false
    local total_lines
    total_lines=$(wc -l <"${book_file}" | xargs)
    local current_line=1
    local total_cache_lines=0
    local current_cache_line=0
    local finish=false
    _add_book_in_tube_top "${book_name}" "${reading}" "${total_lines}" "${current_line}" "${total_cache_lines}" "${current_cache_line}" "${finish}"

    return 0
}

print() {
    if (($# != 1)); then
        echo "start to read a book:"
        echo "$script -s book_name"
        exit 1
    fi

    local book_name="${1}"

    if ! book=$(_query_book_in_tube_top "${book_name}"); then
        echo "error:the book:${book_name} was not found,when deleting in ${tube_top}"
        exit 1
    fi

    local last_reading_book_name
    last_reading_book_name=$(_query_the_reading_book_in_tube_top)
    if [[ "${book_name}" != "${last_reading_book_name}" ]]; then
        #change the reading status of other books to false
        #-E:启用扩展正则表达式(ERE),使正则表达式语法更简洁(无需转义括号()等)
        #([^,]*,):
        #([^,]*,):匹配非逗号的任意字符([^,],非逗号),后跟一个逗号(,)
        #[^,]*:匹配接下来的字段(直到下一个逗号或行尾)
        #\1false:
        #\1:表示正则表达式中第一个捕获组([^,]*,),即匹配的第一个字段加逗号
        #false:将第二字段替换为false
        sed -i -E 's/^(([^,]*,))[^,]*/\1false/' "${tube_top}"

        #set the reading status of this book to true
        _update_book_in_tube_top "${book_name}" 2 true
    fi

    if [[ -z $(_get_book_cache_file "${book_name}") ]]; then
        #make a cache of this book
        _cache "${book_name}"
    fi
    local book_cache_file
    book_cache_file=$(_get_book_cache_file "${book_name}")

    book=$(_query_book_in_tube_top "${book_name}")
    IFS=',' read -r -a parts <<<"${book}"
    local total_lines="${parts[2]}"
    local current_line="${parts[3]}"
    local total_cache_lines="${parts[4]}"
    local current_cache_line="${parts[5]}"
    local finish="${parts[6]}"

    if [[ "${finish}" == true ]]; then
        echo "You have finished the book:${book_name}"
        exit 0
    fi

    #是否需要回退
    if ((current_cache_line + show_lines_number - 1 > total_cache_lines)); then
        #是否能够回退
        if [[ "${current_line}" -lt "${total_lines}" ]]; then
            #回退current line in the entire book
            current_line_back_count=$((total_cache_lines - current_cache_line + 1))
            current_line=$((current_line - current_line_back_count))

            _update_book_in_tube_top "${book_name}" 4 "${current_line}"
            _cache "${book_name}"

            #更新变量
            book=$(_query_book_in_tube_top "${book_name}")
            IFS=',' read -r -a parts <<<"${book}"
            local total_lines="${parts[2]}"
            local current_line="${parts[3]}"
            local total_cache_lines="${parts[4]}"
            local current_cache_line="${parts[5]}"
        fi
    fi

    local left_cache_lines
    left_cache_lines=$((total_cache_lines - current_cache_line + 1))
    local show_lines_real_number
    if [[ "${left_cache_lines}" -lt "${show_lines_number}" ]]; then
        show_lines_real_number="${left_cache_lines}"
    else
        show_lines_real_number="${show_lines_number}"
    fi

    if [[ "${show_lines_real_number}" -ne 0 ]]; then
        #without line number
        #tail -n +"${current_cache_line}" "${book_cache_file}" | head -n "${show_lines_real_number}"
        #with line number
        #nl -v$((current_line - total_cache_lines)) "${book_cache_file}" | tail -n +"${current_cache_line}" | head -n "${show_lines_real_number}"
        #with line number
        awk -v start="$current_cache_line" -v number="$show_lines_real_number" -v origin_current_line="$current_line" -v cache_total_lines="$total_cache_lines" 'NR>=start && NR<(start + number) {print (origin_current_line - cache_total_lines - 1 + NR), $0}' "${book_cache_file}"

        #update current cache line
        current_cache_line=$((current_cache_line + show_lines_real_number))
        _update_book_in_tube_top "${book_name}" 6 "${current_cache_line}"
    fi

    if [[ "${current_line}" -gt "${total_lines}" && "${current_cache_line}" -gt "${total_cache_lines}" ]]; then
        #update the finish flag
        _update_book_in_tube_top "${book_name}" 7 true
        echo "You have finished the book:${book_name}"
        exit 0
    fi

    return 0
}

main() {
    required_tools

    parse_options "${@}"
}

main "${@}"
