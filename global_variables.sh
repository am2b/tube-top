#!/usr/bin/env bash

#shellcheck disable=SC2034

if [[ -z "$GLOBAL_VARIABLES_LOADED" ]]; then
    export GLOBAL_VARIABLES_LOADED=1

    #config:
    CONFIG_DIR="${HOME}"/.config/tube-top
    CONFIG_FILE="${CONFIG_DIR}"/config
    cache_lines_number=0
    show_lines_number=0
    enable_line_number=0
    enable_color=0
    backup_dir=""

    #dirs:
    ROOT_DIR="${HOME}"/.tube-top
    BOOKS_DIR="${ROOT_DIR}"/books
    CACHE_DIR="${ROOT_DIR}"/cache

    BOOK_FILE=""
    BOOK_CACHE_FILE=""

    #records of books
    TUBE_TOP="${ROOT_DIR}"/tube_top
    BOOK_NAME=""
    ALIAS="none"
    READING=false
    TOTAL_LINES=0
    CUR_LINE=1
    CACHE_TOTAL_LINES=0
    CACHE_CUR_LINE=0
    FINISH=false

    #messages
    msg_no_reading_book=$(
        cat <<EOF
error: there are no books currently being read
usage: you can execute the following command to set the book you are reading:
tube_top.sh -p book_name
EOF
    )
fi
