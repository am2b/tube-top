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

    #注意:参数要用双引号扩起来,以仅表达字符串而不是全局变量
    _get_field_num() {
        local field_name
        field_name="${1}"

        case "${field_name}" in
        "BOOK_NAME")
            echo 1
            ;;
        "ALIAS")
            echo 2
            ;;
        "READING")
            echo 3
            ;;
        "TOTAL_LINES")
            echo 4
            ;;
        "CUR_LINE")
            echo 5
            ;;
        "CACHE_TOTAL_LINES")
            echo 6
            ;;
        "CACHE_CUR_LINE")
            echo 7
            ;;
        "FINISH")
            echo 8
            ;;
        *)
            exit 1
            ;;
        esac
    }

    #根据全局变量BOOK_NAME来查询其record
    _query_book_in_tube_top() {
        local record
        record=$(sed -n "/^$BOOK_NAME,/p" "${TUBE_TOP}")
        if [[ -n $record ]]; then
            echo "${record}"
            return 0
        else
            return 1
        fi
    }

    #根据参数给出的别名来查询第一列的book name
    _get_book_name_by_alias() {
        local alias_name
        alias_name="${1}"

        local book_name
        local alias_field_num
        alias_field_num=$(_get_field_num "ALIAS")
        book_name=$(awk -F',' -v alias_field_num="$alias_field_num" -v alias_name="$alias_name" '$(alias_field_num) == alias_name { print $1; exit }' "${TUBE_TOP}")
        if [[ -n $book_name ]]; then
            echo "${book_name}"
            return 0
        else
            return 1
        fi
    }

    #根据命令行给出的参数来设置BOOK_NAME
    _set_BOOK_NAME_by_parameter() {
        #先假设给出的参数是book name
        BOOK_NAME="${1}"

        if ! _query_book_in_tube_top >/dev/null; then
            #说明不是book name,有可能是别名
            if book_name=$(_get_book_name_by_alias "${1}"); then
                #返回值为0,说明在tube_top文件中查询到了别名
                BOOK_NAME="${book_name}"
            else
                echo "invalid parameter:${1}"
                exit 1
            fi
        fi
    }

    #注意:该函数返回的是一个完整的record
    _query_the_reading_book_in_tube_top() {
        local record
        local reading_field_num
        reading_field_num=$(_get_field_num "READING")

        record=$(awk -F, -v reading_field_num="$reading_field_num" '$(reading_field_num) == "true"' "${TUBE_TOP}")

        if [[ -n $record ]]; then
            echo "${record}"
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

    #注意:该函数返回的是一个完整的record
    _query_the_previous_reading_book_in_tube_top() {
        local record
        local reading_field_num
        reading_field_num=$(_get_field_num "READING")

        record=$(awk -F, -v reading_field_num="$reading_field_num" '$(reading_field_num) == "previous"' "${TUBE_TOP}")

        if [[ -n $record ]]; then
            echo "${record}"
            return 0
        else
            return 1
        fi
    }

    #注意:该函数返回的是上一本被阅读的书的book name
    _get_the_previous_reading_book_name() {
        local book
        local previous_reading_book_name
        if book=$(_query_the_previous_reading_book_in_tube_top); then
            IFS=',' read -r -a parts <<<"${book}"
            previous_reading_book_name="${parts[0]}"
        fi

        if [[ -n $previous_reading_book_name ]]; then
            echo "${previous_reading_book_name}"
            return 0
        else
            return 1
        fi
    }

    #修改匹配BOOK_NAME的record的某一个字段
    #注意:参数要用双引号扩起来,以仅表达字符串而不是全局变量
    _update_field_in_tube_top() {
        local field_name
        local new_value
        field_name="${1}"
        new_value="${2}"

        local field_num
        field_num=$(_get_field_num "${field_name}")
        awk -F, -v book_name="$BOOK_NAME" -v field_num="$field_num" -v new_value="$new_value" '
            BEGIN {OFS=","} 
            $1 == book_name { $(field_num) = new_value } {print}
        ' "${TUBE_TOP}" >/tmp/tube_top.txt && mv /tmp/tube_top.txt "${TUBE_TOP}"
    }

    #修改全部records的某一个字段
    #注意:参数要用双引号扩起来,以仅表达字符串而不是全局变量
    _update_field_of_all_records_in_tube_top() {
        local field_name
        local field_num
        local new_value
        field_name="${1}"
        field_num=$(_get_field_num "${field_name}")
        new_value="${2}"

        awk -F, -v field_num="$field_num" -v new_value="$new_value" '
            BEGIN {OFS=","}
            {
                $(field_num)=new_value
                print
            }
        ' "${TUBE_TOP}" >/tmp/tube_top.txt && mv /tmp/tube_top.txt "${TUBE_TOP}"
    }

    _delete_book_from_tube_top() {
        sed -i "/^$BOOK_NAME,/d" "${TUBE_TOP}"
    }

    _cache() {
        BOOK_NAME=$(_get_the_reading_book_name)

        #for add
        if [[ -n "${1}" ]]; then
            BOOK_NAME="${1}"
        fi

        if [[ -z $BOOK_NAME ]]; then
            echo "${msg_no_reading_book} when caching"
            exit 1
        fi

        BOOK_FILE="${BOOKS_DIR}"/"${BOOK_NAME}"
        if [[ ! -f "${BOOK_FILE}" ]]; then
            echo "error:the book file:${BOOK_FILE} was not found in ${BOOKS_DIR} when caching"
            exit 1
        fi

        local cache_lines_count
        #check if cur_line+cache_lines_number exceeds the total lines
        if ((CUR_LINE + cache_lines_number - 1 > TOTAL_LINES)); then
            cache_lines_count=$((TOTAL_LINES - CUR_LINE + 1))
        else
            cache_lines_count="${cache_lines_number}"
        fi

        #for add
        if [[ -z "${BOOK_CACHE_FILE}" ]]; then
            BOOK_CACHE_FILE="${CACHE_DIR}"/"${BOOK_NAME}"
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
            echo "cache_lines_number=1000" >>"${CONFIG_FILE}"
            echo "show_lines_number=10" >>"${CONFIG_FILE}"
            echo "enable_line_number=1" >>"${CONFIG_FILE}"
            echo "enable_color=1" >>"${CONFIG_FILE}"
            echo "backup_dir=$HOME/backups/tube-top" >>"${CONFIG_FILE}"
        fi

        if [[ ! -f "${COLORS_FILE}" ]]; then
            local colors=(
                "\033[32m"       #绿色
                "\033[33m"       #黄色
                "\033[34m"       #蓝色
                "\033[38;5;172m" #棕色
                "\033[36m"       #青色
                "\033[35m"       #紫色
                "\033[38;5;130m" #深橙色
                "\033[38;5;24m"  #暗青蓝色
                "\033[38;5;22m"  #深绿色
                "\033[38;5;58m"  #橄榄色
                "\033[38;5;95m"  #深洋红色
                "\033[90m"       #灰色
            )
            printf "%s\n" "${colors[@]}" >"${COLORS_FILE}"
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
        backup_dir=$(_get_config_value "backup_dir")
    }

    #首先查询到当前全局变量BOOK_NAME的record,然后根据该record来填充其余的全局变量
    _read_record_from_tupe_top() {
        if record=$(_query_book_in_tube_top); then
            IFS=',' read -r -a parts <<<"${record}"
            ALIAS="${parts[1]}"
            READING="${parts[2]}"
            TOTAL_LINES="${parts[3]}"
            CUR_LINE="${parts[4]}"
            CACHE_TOTAL_LINES="${parts[5]}"
            CACHE_CUR_LINE="${parts[6]}"
            FINISH="${parts[7]}"
        fi
    }

    _write_record_to_tupe_top() {
        _delete_book_from_tube_top
        echo "${BOOK_NAME}","${ALIAS}","${READING}","${TOTAL_LINES}","${CUR_LINE}","${CACHE_TOTAL_LINES}","${CACHE_CUR_LINE}","${FINISH}" >>"${TUBE_TOP}"
    }
fi
