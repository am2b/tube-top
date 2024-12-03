#!/usr/bin/env bash

#dirs:
root_dir="${HOME}"/.tube-top
books_dir="${root_dir}"/books
cache_dir="${root_dir}"/cache
#progress_dir="${root_dir}"/progress

#files:
#the base name of current book
#book_name=""

#the structure of "${tube_top}"
#book name,total lines,current line,reading
tube_top="${root_dir}"/tube_top

#by default,10 lines are printed
show_lines_number=10

cache_lines_number=1000
#real book file
#current_book=""
#real book's cache file
#current_book_cache=""
#a text file to record the progress of all books
#books_progress="${progress_dir}"/books.txt
#a text file to record the progress of current book
#current_book_progress=""

usage() {
    local script
    script=$(basename "$0")
    echo "Usage:"
    echo "${script} -h:show usage"
    #echo "${script} -i:init tube-top"
    #initialize a book and start reading from the beginning
    echo "${script} -b book_file:init a book to read from the beginning"
    #pick up a book you've read before and continue reading
    echo "${script} -r book_name:read a book"
    echo "${script} -j line_number:jump to line_number"
    echo "${script} -d book_name:delete a book"
    echo "${script}:print tube top in terminal"
    echo "${script} -l:list the books you have read"
    echo "${script} -c:clear all settings and caches"
    exit 0
}

parse_options() {
    while getopts ":hb:r:j:d:lc" opt; do
        case "${opt}" in
        h)
            usage
            ;;
        b)
            init_book "$OPTARG"
            ;;
        r)
            pickup_book "$OPTARG"
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
    result=$(sed -n '/^\([^,]*,\)\{3\}true,/p' "${tube_top}")
    if [[ -n $result ]]; then
        echo "${result}"
        return 0
    else
        return 1
    fi
}

_add_book_in_tube_top() {
    local book_name="${1}"
    local total_lines="${2}"
    local current_line="${3}"
    local reading="${4}"
    if ! book=$(_query_book_in_tube_top "${book_name}"); then
        echo "${book_name}","${total_lines}","${current_line}","${reading}" >> "${tube_top}"
    else
        echo "error:the book:${book_name} was found,when adding in ${tube_top}"
        exit 1
    fi
}

_delete_book_from_tube_top() {
    local book_name="${1}"
    sed -i '' "/^$book_name,/d" "${tube_top}"
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

    if book=$(_query_book_in_tube_top "${book_name}"); then
        IFS=',' read -r -a parts <<<"${book}"
        local total_lines="${parts[1]}"
        local current_line="${parts[2]}"
        local cache_lines_count="${cache_lines_number}"

        #check if current_line+cache_lines_number exceeds the total lines
        if ((current_line + cache_lines_number > total_lines)); then
            cache_lines_count=$((total_lines - current_line))
        fi

        local book_file
        book_file=$(_get_book_file "${book_name}")
        local book_cache_file="${cache_dir}"/"${book_name}"
        awk "NR>=${current_line} && NR<${current_line}+${cache_lines_count}" "${book_file}" >"${book_cache_file}"
    else
        echo "error:the book:${book_name} was not found when caching"
        exit 1
    fi
}

init_book() {
    local book_file="${1}"

    if [[ ! -f "${tube_top}" ]]; then
        _init
    fi

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

    book_name=$(basename "$book_file")
    #check if the library already has this book
    if _get_book_file "${book_name}"; then
        echo "error:the library already contains a book with the same name:${book_name}"
        exit 1
    fi

    #save this book to the library
    cp "${book_file}" "${books_dir}"

    #register this book
    total_lines=$(wc -l <"${1}" | xargs)
    current_line=1
    _add_book_in_tube_top "${book_name}" "${total_lines}" "${current_line}" false

    #make a cache of this book
    #_cache "${book_name}"
}

pickup_book() {
    #change the reading status of other books to false, and set the reading status of this book to true
}

#print() {
#}

#clear() {
#}

main() {
    parse_options "${@}"
}

main "${@}"
