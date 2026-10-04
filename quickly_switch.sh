#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

quickly_switch() {
    local title
    title=$(_get_title_of_the_previous)
    if [[ -n "${title}" ]]; then
        pin "${title}"
        print_last_again
        exit 0
    else
        echo "error:there is no previous book"
        echo "usage: you can execute the following command to set the book you want to read:"
        echo "tube_top.sh -p title"
        exit 1
    fi
}
