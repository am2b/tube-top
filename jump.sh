#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh
source "${SELF_ABS_DIR}"/cache.sh

#记住当前这屏的起始行号,等-j 0时跳回去
#参数:title
_hold_the_starting_line_number() {
    check_parameters 1 -- "$@" || exit $?

    local title
    title="${1}"
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    local record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:jump"
        exit 1
    fi

    local original_total_lines original_next_line
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    local record_for_jump_back
    record_for_jump_back=/tmp/tube_top_jump

    local pos
    pos=$((original_next_line - 1 - cache_total_lines + cache_next_line))
    #没读过一整屏就不记录,因为没东西可回跳
    if ((pos > SHOW_LINES_NUMBER)); then
        echo $((pos - SHOW_LINES_NUMBER)) > "${record_for_jump_back}"
    fi
}

#参数:[+/-]num/0/e(无符号整数,有符号整数,0,e)
jump() {
    check_parameters 1 -- "$@" || exit $?

    local number="$1"
    local error_message
    error_message="parameter error, please enter a line number, you can use a positive or negative sign to indicate how many lines to jump back or forward"

    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    local record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:jump"
        exit 1
    fi

    local original_total_lines original_next_line
    original_total_lines=$(_get_original_total_lines_of_record "${record}")
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    local record_for_jump_back
    record_for_jump_back=/tmp/tube_top_jump

    #如果number是一个以+开头的整数‌的话
    if [[ "$number" =~ ^\+[0-9]+$ ]]; then
        #向后跳
        local number_without_sign
        number_without_sign="${number#[-+]}"
        #缓存中还没有被打印的行数
        local cache_down_lines
        #要改
        #如果cache_file不存在的话,这里计算的结果为1
        cache_down_lines=$((cache_total_lines - cache_next_line + 1))
        if ((cache_down_lines >= number_without_sign)); then
            _hold_the_starting_line_number "${title}"
            cache_next_line=$((cache_next_line + number_without_sign))
            _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" "${cache_next_line}"
            return 0
        else
            number=$((original_next_line + number_without_sign - cache_down_lines))
        fi
    #如果number是一个以-开头的整数‌的话
    elif [[ "$number" =~ ^-[0-9]+$ ]]; then
        #向前跳
        local number_without_sign
        number_without_sign="${number#[-+]}"
        #缓存中已经被打印的行数
        local cache_up_lines
        #要改
        #如果cache_file不存在的话,这里计算的结果为-1
        cache_up_lines=$((cache_next_line - 1))
        if ((cache_up_lines >= number_without_sign)); then
            _hold_the_starting_line_number "${title}"
            cache_next_line=$((cache_next_line - number_without_sign))
            _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" "${cache_next_line}"
            return 0
        else
            number=$((original_next_line - cache_total_lines + cache_up_lines - number_without_sign))
        fi
    fi

    #jump to the end
    if [[ "${number}" == 'e' ]]; then
        number=$(((original_total_lines - 1) / SHOW_LINES_NUMBER * SHOW_LINES_NUMBER + 1))
    fi

    #如果number是一个非负整数的话(跳转到绝对行号)
    if [[ "$number" =~ ^[0-9]+$ ]]; then
        #跳到实际的行号
        if ((number <= original_total_lines)) && ((number > 0)); then
            #要改
            #如果cache_file不存在的话,这里写入的结果为-1
            _hold_the_starting_line_number "${title}"
            original_next_line="${number}"
            _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"
        elif ((number == 0)); then
            #jump back
            if [[ ! -f "${record_for_jump_back}" ]]; then return 0; fi
            local hold_cur_line
            hold_cur_line="${original_next_line}"

            local back_value
            back_value=$(cat "${record_for_jump_back}")
            #读到负数或0就不跳
            if [[ ! "${back_value}" =~ ^[0-9]+$ ]] || ((back_value < 1)); then
                return 0
            fi
            original_next_line="${back_value}"
            _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"
            #!!!如果cache_file不存在的话,这里写入的结果要实际测试一下
            echo $((hold_cur_line - 1 - cache_total_lines + cache_next_line - SHOW_LINES_NUMBER)) > "${record_for_jump_back}"
        else
            echo "${error_message}"
            exit 1
        fi

        _delete_cache_file "${title}"
        _update_field_in_tube_top "${title}" "CACHE_TOTAL_LINES" 0
        _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" 1
    else
        echo "${error_message}"
        exit 1
    fi
}

#没有参数
jump_to_last() {
    local title
    title=$(_get_title_of_the_reading_book)
    if [[ -z $title ]]; then
        echo "${MSG_NO_READING_BOOK}"
        exit 1
    fi

    local record
    if ! record=$(_get_record "${title}"); then
        echo "error:get record of title:${title} failed in function:jump"
        exit 1
    fi

    local original_next_line
    original_next_line=$(_get_original_next_line_of_record "${record}")

    local cache_total_lines cache_next_line
    cache_total_lines=$(_get_cache_total_lines_of_record "${record}")
    cache_next_line=$(_get_cache_next_line_of_record "${record}")

    #缓存中下次要读取的行,其上面的行数
    local cache_up_lines
    cache_up_lines=$((cache_next_line - 1))
    if ((cache_up_lines >= SHOW_LINES_NUMBER)); then
        cache_next_line=$((cache_next_line - SHOW_LINES_NUMBER))
        _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" "${cache_next_line}"
    else
        #回退
        local pos target
        pos=$((original_next_line - 1 - cache_total_lines + cache_next_line))
        target=$((pos - SHOW_LINES_NUMBER))
        if ((target < 1)); then target=1; fi
        original_next_line=$target

        _update_field_in_tube_top "${title}" "ORIGINAL_NEXT_LINE" "${original_next_line}"
        _delete_cache_file "${title}"
        _update_field_in_tube_top "${title}" "CACHE_TOTAL_LINES" 0
        _update_field_in_tube_top "${title}" "CACHE_NEXT_LINE" 1
    fi
}
