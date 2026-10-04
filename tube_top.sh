#!/usr/bin/env bash

set -uo pipefail

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/assistant.sh
source "${SELF_ABS_DIR}"/impl.sh
source "${SELF_ABS_DIR}"/add.sh
source "${SELF_ABS_DIR}"/pin.sh
source "${SELF_ABS_DIR}"/set_alias.sh
source "${SELF_ABS_DIR}"/quickly_switch.sh
source "${SELF_ABS_DIR}"/print.sh
source "${SELF_ABS_DIR}"/cache.sh
source "${SELF_ABS_DIR}"/page_up.sh
source "${SELF_ABS_DIR}"/jump.sh
source "${SELF_ABS_DIR}"/search.sh
source "${SELF_ABS_DIR}"/ocd.sh
source "${SELF_ABS_DIR}"/delete.sh
source "${SELF_ABS_DIR}"/reset.sh
source "${SELF_ABS_DIR}"/list.sh
source "${SELF_ABS_DIR}"/backup.sh

main() {
    #检查工具
    required_tools

    #make sure配置文件,颜色文件,数据库文件
    _tube_top_init

    #从配置文件中读取值
    _read_config

    #解析选项
    parse_options "${@}"
}

main "${@}"
