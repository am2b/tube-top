#!/usr/bin/env bash

if [[ -z "$GLOBAL_VARIABLES_LOADED" ]]; then
    export GLOBAL_VARIABLES_LOADED=1

    #config:
    CONFIG_DIR="${HOME}"/.config/tube-top
    CONFIG_FILE="${CONFIG_DIR}"/config
    cache_lines_number=0
    show_lines_number=0
    enable_line_number=0
    enable_color=0

    #dirs:
    ROOT_DIR="${HOME}"/.tube-top
    BOOKS_DIR="${ROOT_DIR}"/books
    CACHE_DIR="${ROOT_DIR}"/cache

    BOOK_FILE=""
    BOOK_CACHE_FILE=""

    #records of books
    TUBE_TOP="${ROOT_DIR}"/tube_top
    BOOK_NAME=""
    READING=false
    TOTAL_LINES=0
    CUR_LINE=0
    CACHE_TOTAL_LINES=0
    CACHE_CUR_LINE=0
    FINISH=false
fi
