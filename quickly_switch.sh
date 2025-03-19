#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

quickly_switch() {
    backup

    local previous_book_name
    previous_book_name=$(_get_the_previous_reading_book_name)
    if [[ -n "${previous_book_name}" ]]; then
        pin "${previous_book_name}"
        print_last_again

        exit 0
    else
        echo "error:there is no previous book"
        echo "usage: you can execute the following command to set the book you want to read:"
        echo "tube_top.sh -p book_name"
        exit 1
    fi
}
