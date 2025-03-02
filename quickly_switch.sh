#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

quickly_switch() {
    backup

    local previous_book_name
    previous_book_name=$(_get_the_previous_reading_book_name)
    pin "${previous_book_name}"

    print_last_again

    exit 0
}
