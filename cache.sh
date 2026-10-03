#!/usr/bin/env bash

_do_cache() {
    local original_total_lines original_next_line
    original_total_lines=$(_get_original_total_lines_of_record "${record}")
    original_next_line=$(_get_original_next_line_of_record "${record}")

    #需要缓存多少行
    local cache_lines_count
    if ((original_next_line + CACHE_LINES_NUMBER - 1 > original_total_lines)); then
        cache_lines_count=$((original_total_lines - original_next_line + 1))
    else
        cache_lines_count="${CACHE_LINES_NUMBER}"
    fi

    #do cache
    awk "NR>=${original_next_line} && NR<${original_next_line}+${cache_lines_count}" "${book_file}" > "${cache_file}"

    #update total cache lines and current cache line
    local cache_total_lines cache_next_line
    cache_total_lines=$(wc -l < "${cache_file}" | xargs)
    cache_next_line=1
    _update_field_in_tube_top "${title}" "CACHE_TOTAL_LINES" "${cache_total_lines}"
    _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" "${cache_next_line}"

    #update current line in the book file
    original_next_line=$((original_next_line + cache_lines_count))
    _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"
}

_cache() {
    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    local book_file
    book_file="${BOOKS_DIR}"/"${title}"
    local cache_file
    cache_file="${CACHE_DIR}"/"${title}"

    if [[ ! -f "${book_file}" ]]; then
        echo "error:the book file:${book_file} was not found in ${BOOKS_DIR} in function:_cache"
        exit 1
    fi

    local record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:_do_print"
        exit 1
    fi

    #需要做cache的3中情形:
    #1,还没有cache
    if [[ ! -f "${cache_file}" ]]; then
        _do_cache
        return 0
    fi

    #2,cache在上次刚好被完美地消耗完了
    if ((cache_next_line == cache_total_lines + 1)); then
        _do_cache
        return 0
    fi

    #3,cache剩下的行数小于SHOW_LINES_NUMBER
    local cache_left_lines
    cache_left_lines=$((cache_total_lines - cache_next_line + 1))
    if ((cache_left_lines < SHOW_LINES_NUMBER)); then
        #book file里是否还有剩余的行
        local origin_left_lines
        origin_left_lines=$((original_total_lines - original_next_line + 1))
        if ((origin_left_lines > 0)); then
            #那就把cache剩下的行"回退"给book file后,再做cache
            original_next_line=$((original_next_line - cache_left_lines))
            _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"
            _do_cache
            return 0
        fi
        #如果book file里面没有剩余的行了,那就把cache里面剩下的打印了,也不必再做cache了
    fi
}
