#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/assistant.sh
source "${SELF_ABS_DIR}"/impl.sh
source "${SELF_ABS_DIR}"/add.sh
source "${SELF_ABS_DIR}"/pin.sh
source "${SELF_ABS_DIR}"/print.sh
source "${SELF_ABS_DIR}"/jump.sh
source "${SELF_ABS_DIR}"/delete.sh
source "${SELF_ABS_DIR}"/reset.sh

main() {
    required_tools

    _tube_top_init

    _read_config

    parse_options "${@}"

    _write_record_to_tupe_top
}

main "${@}"
