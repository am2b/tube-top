#!/usr/bin/env bash

#shellcheck disable=SC2034

if [[ -z "$GLOBAL_VARIABLES_LOADED" ]]; then
    export GLOBAL_VARIABLES_LOADED=1

    #config:
    CONFIG_DIR="${HOME}"/.config/tube-top
    CONFIG_FILE="${CONFIG_DIR}"/config
    COLORS_FILE="${CONFIG_DIR}"/colors
    backup_dir=""
    #每次从原始文件里面缓存多少行(默认1000行)
    cache_lines_number=0
    #每次打印多少行(默认10行)
    show_lines_number=0
    #是否打印行号(默认开启)
    enable_line_number=0
    #是否彩色打印(默认开启)
    enable_color=0

    #存放书籍以及数据库文件的目录
    ROOT_DIR="${HOME}"/.tube-top
    BOOKS_DIR="${ROOT_DIR}"/books
    CACHE_DIR="${ROOT_DIR}"/cache

    #当前正在读的书的文件名和缓存名(如果没有正在读的书,那么就为空字符串)
    BOOK_FILE=""
    BOOK_CACHE_FILE=""

    #数据库文件(~/.tube-top/tube_top)的格式
    #第0列
    TUBE_TOP="${ROOT_DIR}"/tube_top
    #第1列
    BOOK_NAME=""
    #第2列
    ALIAS="none"
    #第3列
    READING=false
    #第4列:原始文件的总行数
    TOTAL_LINES=0
    #第5列:在原始文件中,下次从哪一行开始读
    CUR_LINE=1
    #第6列:缓存文件的总行数
    CACHE_TOTAL_LINES=0
    #第7列:在缓存文件中,下次从哪一行开始读
    CACHE_CUR_LINE=0
    #第8列:是否已经读完了(没有可打印的了)
    FINISH=false
    #第9列:这本书是否曾经读完过
    EVER_FINISHED=false

    #messages
    msg_no_reading_book=$(
        cat << EOF
error: there are no books currently being read
usage: you can execute the following command to set the book you want to read:
tube_top.sh -p book_name
EOF
    )
fi
