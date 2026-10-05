#!/usr/bin/env bash

quickly_switch() {
    local title
    title=$(_get_title_of_the_previous)
    if [[ -n "${title}" ]]; then
        pin "${title}"
        print_last_again
        exit 0
    else
        echo "error:there is no previous book" >&2
        echo "usage: you can execute the following command to set the book you want to read:" >&2
        echo "tube_top.sh -p title" >&2
        exit 1
    fi
}
