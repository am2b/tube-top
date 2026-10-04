#!/usr/bin/env bash

#source是在当前shell进程里执行的,被source的脚本里不要用exit

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

if [[ -z "$IMPL_LOADED" ]]; then
    export IMPL_LOADED=1

    #检查参数
    #用法示例(第1,2,3个参数是必须的,不是可选参数):check_parameters 1 2 3 -- "$@" || return/exit $?
    check_parameters() {
        #FUNCNAME[0]:当前正在执行的函数(这里是check_parameters),FUNCNAME[1]:调用者
        #:-<script>:万一check_parameters在脚本顶层(没有外层函数)被调用,FUNCNAME[1]未设置,就显示<script>
        local fn=${FUNCNAME[1]:-<script>}
        #存储序号(1 2 3)的数组
        local idx
        idx=()

        #把--之前的所有token都收进idx
        while (($#)) && [[ $1 != -- ]]; do
            idx+=("$1")
            shift
        done

        #make sure "--" 存在
        if (($# == 0)); then
            printf 'usage: check_parameters <idx...> -- <args...>\n' >&2
            return 2
        fi
        shift

        #遍历序号
        for i in "${idx[@]}"; do
            #检查参数个数够不够
            if ((i > $#)); then
                printf 'error: missing parameter %d in %s\n' "$i" "$fn" >&2
                return 1
            fi

            #检查参数是不是空串
            #${!i}:是间接展开,把i的值当作变量名,再取那个变量的值
            [[ -n ${!i} ]] || {
                printf 'error: the parameter %d is empty in %s\n' "$i" "$fn" >&2
                return 1
            }
        done
    }

    _get_config_value() {
        check_parameters 1 -- "$@" || return $?

        local key="${1}"
        local value
        value=$(awk -F= -v k="$key" '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); if ($1 == k) print $2}' "${CONFIG_FILE}")

        echo "${value}"
        return 0
    }

    #注意:参数要用双引号扩起来,以仅表达字符串而不是全局变量
    _get_field_num() {
        check_parameters 1 -- "$@" || return $?

        local field_name
        field_name="${1}"

        case "${field_name}" in
            "TITLE")
                echo 1
                ;;
            "ALIAS")
                echo 2
                ;;
            "READING")
                echo 3
                ;;
            "ORIGINAL_TOTAL_LINES")
                echo 4
                ;;
            "ORIGINAL_NEXT_LINE")
                echo 5
                ;;
            "CACHE_TOTAL_LINES")
                echo 6
                ;;
            "CACHE_NEXT_LINE")
                echo 7
                ;;
            "FINISH")
                echo 8
                ;;
            "EVER_FINISHED")
                echo 9
                ;;
            *)
                return 1
                ;;
        esac
    }

    #返回title的record
    _get_record() {
        check_parameters 1 -- "$@" || return $?

        local title
        title="${1}"

        local record
        record=$(sed -n "/^$title,/p" "${TUBE_TOP}")
        if [[ -n $record ]]; then
            echo "${record}"
            return 0
        else
            return 1
        fi
    }

    #根据参数给出的别名来查询第一列的title
    _get_title_by_alias() {
        check_parameters 1 -- "$@" || return $?

        local alias
        alias="${1}"

        local title
        local alias_field_num
        alias_field_num=$(_get_field_num "ALIAS")
        title=$(awk -F',' -v alias_field_num="$alias_field_num" -v alias="$alias" '$(alias_field_num) == alias { print $1; exit }' "${TUBE_TOP}")
        if [[ -n $title ]]; then
            echo "${title}"
            return 0
        else
            return 1
        fi
    }

    #从用户输入(title,alias)获取到title
    _get_title_from_input() {
        check_parameters 1 -- "$@" || return $?

        local input title
        input="$1"

        result=$(awk -F',' -v value="$input" '
            $1 == value {
                print "1"
                exit
            }
            $2 == value {
                print "2"
                exit
            }
            ' "${TUBE_TOP}")

        case "$result" in
            1)
                title="${input}"
                ;;
            2)
                title=$(_get_title_by_alias "${input}")
                ;;
            *)
                echo "error:the parameter is neither title nor an alias in function:reset_book"
                return 1
                ;;
        esac

        echo "${title}"
    }

    #获取正在读的书的record,返回的是一个完整的record
    _get_record_of_the_reading_book() {
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

    #获取正在读的书的title
    _get_title_of_the_reading_book() {
        local record
        local title
        if record=$(_get_record_of_the_reading_book); then
            IFS=',' read -r -a parts <<< "${record}"
            title="${parts[0]}"
        fi

        if [[ -n $title ]]; then
            echo "${title}"
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

    #返回previous的title
    _get_title_of_the_previous() {
        local record
        local title
        if record=$(_query_the_previous_reading_book_in_tube_top); then
            IFS=',' read -r -a parts <<< "${record}"
            title="${parts[0]}"
        fi

        if [[ -n $title ]]; then
            echo "${title}"
            return 0
        else
            return 1
        fi
    }

    #修改给定title的record的某一个字段
    _update_field_in_tube_top() {
        check_parameters 1 2 3 -- "$@" || return $?

        local title
        local field_name
        local new_value
        title="${1}"
        field_name="${2}"
        new_value="${3}"

        local field_num
        field_num=$(_get_field_num "${field_name}")
        awk -F, -v title="$title" -v field_num="$field_num" -v new_value="$new_value" '
            BEGIN {OFS=","} 
            $1 == title { $(field_num) = new_value } {print}
        ' "${TUBE_TOP}" > /tmp/tube_top.txt && mv /tmp/tube_top.txt "${TUBE_TOP}"
    }

    #make sure配置文件,颜色文件,数据库文件
    _tube_top_init() {
        if [[ ! -d "${CONFIG_DIR}" ]]; then
            mkdir -p "${CONFIG_DIR}"
        fi

        if [[ ! -f "${CONFIG_FILE}" ]]; then
            echo "cache_lines_number=1000" >> "${CONFIG_FILE}"
            echo "show_lines_number=10" >> "${CONFIG_FILE}"
            echo "enable_line_number=1" >> "${CONFIG_FILE}"
            echo "enable_color=1" >> "${CONFIG_FILE}"
            echo "backup_dir=$HOME/backups/tube-top" >> "${CONFIG_FILE}"
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
            printf "%s\n" "${colors[@]}" > "${COLORS_FILE}"
        fi

        if [[ ! -d $ROOT_DIR ]]; then mkdir -p "${ROOT_DIR}"; fi
        if [[ ! -d $BOOKS_DIR ]]; then mkdir -p "${BOOKS_DIR}"; fi
        if [[ ! -d $CACHE_DIR ]]; then mkdir -p "${CACHE_DIR}"; fi

        if [[ ! -f "${TUBE_TOP}" ]]; then touch "${TUBE_TOP}"; fi
    }

    #从配置文件中读取值
    _read_config() {
        CACHE_LINES_NUMBER=$(_get_config_value "cache_lines_number")
        SHOW_LINES_NUMBER=$(_get_config_value "show_lines_number")
        ENABLE_LINE_NUMBER=$(_get_config_value "enable_line_number")
        ENABLE_COLOR=$(_get_config_value "enable_color")
        BACKUP_DIR=$(_get_config_value "backup_dir")
    }

    #解析一条record
    _get_title_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[0]}"
    }

    _get_alias_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[1]}"
    }

    _get_reading_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[2]}"
    }

    _get_original_total_lines_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[3]}"
    }

    _get_original_next_line_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[4]}"
    }

    _get_cache_total_lines_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[5]}"
    }

    _get_cache_next_line_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[6]}"
    }

    _get_finish_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[7]}"
    }

    _get_ever_finish_of_record() {
        check_parameters 1 -- "$@" || return $?

        IFS=',' read -r -a parts <<< "${1}"
        echo "${parts[8]}"
    }

    #删除cache file
    _delete_cache_file() {
        check_parameters 1 -- "$@" || return $?

        local title="${1}"
        local cache_file
        cache_file="${CACHE_DIR}"/"${title}"
        if [[ -f "${cache_file}" ]]; then rm "${cache_file}"; fi
    }
fi
