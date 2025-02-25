#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

if [[ -z "$IMPL_LOADED" ]]; then
    export IMPL_LOADED=1

    _get_config_value() {
        if (("$#" == 1)); then
            local key="${1}"
            local value
            value=$(awk -F= -v k="$key" '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); if ($1 == k) print $2}' "${CONFIG_FILE}")

            echo "${value}"
            return 0
        else
            return 1
        fi
    }

    #根据全局变量BOOK_NAME来查询其record
    _query_book_in_tube_top() {
        local result
        result=$(sed -n "/^$BOOK_NAME,/p" "${TUBE_TOP}")
        if [[ -n $result ]]; then
            echo "${result}"
            return 0
        else
            return 1
        fi
    }

    #注意:该函数返回的是一个完整的record
    _query_the_reading_book_in_tube_top() {
        local result
        #表示reading的true或false位于第2列
        #\([^,]*,\):匹配一个组,即非逗号的字符([^,])的0或多个重复,紧跟一个逗号(,)
        result=$(sed -n '/^\([^,]*,\)true,/p' "${TUBE_TOP}")
        if [[ -n $result ]]; then
            echo "${result}"
            return 0
        else
            return 1
        fi
    }

    #注意:该函数返回的是处于阅读状态的book name
    _get_the_reading_book_name() {
        local book
        local reading_book_name
        if book=$(_query_the_reading_book_in_tube_top); then
            IFS=',' read -r -a parts <<<"${book}"
            reading_book_name="${parts[0]}"
        fi

        if [[ -n $reading_book_name ]]; then
            echo "${reading_book_name}"
            return 0
        else
            return 1
        fi
    }

    _delete_book_from_tube_top() {
        if ! book=$(_query_book_in_tube_top); then
            echo "error:the book:${BOOK_NAME} was not found,when deleting in ${TUBE_TOP}"
        else
            sed -i "/^$BOOK_NAME,/d" "${TUBE_TOP}"
        fi
    }

    _cache() {
        local cache_lines_count
        #check if cur_line+cache_lines_number exceeds the total lines
        if ((CUR_LINE + cache_lines_number - 1 > TOTAL_LINES)); then
            cache_lines_count=$((TOTAL_LINES - CUR_LINE + 1))
        else
            cache_lines_count="${cache_lines_number}"
        fi

        if [[ ! -f "${BOOK_FILE}" ]]; then
            echo "error:the book file:${BOOK_FILE} was not found in ${BOOKS_DIR} when caching"
            exit 1
        fi

        awk "NR>=${CUR_LINE} && NR<${CUR_LINE}+${cache_lines_count}" "${BOOK_FILE}" >"${BOOK_CACHE_FILE}"

        #update total cache lines and current cache line
        CACHE_TOTAL_LINES=$(wc -l <"${BOOK_CACHE_FILE}" | xargs)
        CACHE_CUR_LINE=1

        #update current line in the entire book
        CUR_LINE=$((CUR_LINE + cache_lines_count))
    }

    _tube_top_init() {
        if [[ ! -d "${CONFIG_DIR}" ]]; then
            mkdir -p "${CONFIG_DIR}"
        fi

        if [[ ! -f "${CONFIG_FILE}" ]]; then
            echo "cache_lines_number=10" >>"${CONFIG_FILE}"
            echo "show_lines_number=3" >>"${CONFIG_FILE}"
            echo "enable_line_number=1" >>"${CONFIG_FILE}"
            echo "enable_color=1" >>"${CONFIG_FILE}"
        fi

        if [[ ! -d $ROOT_DIR ]]; then mkdir -p "${ROOT_DIR}"; fi
        if [[ ! -d $BOOKS_DIR ]]; then mkdir -p "${BOOKS_DIR}"; fi
        if [[ ! -d $CACHE_DIR ]]; then mkdir -p "${CACHE_DIR}"; fi

        if [[ ! -f "${TUBE_TOP}" ]]; then touch "${TUBE_TOP}"; fi
    }

    _read_config() {
        #从config中读取值
        cache_lines_number=$(_get_config_value "cache_lines_number")
        show_lines_number=$(_get_config_value "show_lines_number")
        enable_line_number=$(_get_config_value "enable_line_number")
        enable_color=$(_get_config_value "enable_color")
    }

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top() {
        if book=$(_query_book_in_tube_top); then
            IFS=',' read -r -a parts <<<"${book}"
            READING="${parts[1]}"
            TOTAL_LINES="${parts[2]}"
            CUR_LINE="${parts[3]}"
            CACHE_TOTAL_LINES="${parts[4]}"
            CACHE_CUR_LINE="${parts[5]}"
            FINISH="${parts[6]}"
        fi
    }

    _write_record_to_tupe_top() {
        _delete_book_from_tube_top
        echo "${BOOK_NAME}","${READING}","${TOTAL_LINES}","${CUR_LINE}","${CACHE_TOTAL_LINES}","${CACHE_CUR_LINE}","${FINISH}" >>"${TUBE_TOP}"
    }
fi
