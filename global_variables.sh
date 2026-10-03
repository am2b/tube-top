#!/usr/bin/env bash

#shellcheck disable=SC2034

if [[ -z "$GLOBAL_VARIABLES_LOADED" ]]; then
    export GLOBAL_VARIABLES_LOADED=1

    #config:
    CONFIG_DIR="${HOME}"/.config/tube-top
    CONFIG_FILE="${CONFIG_DIR}"/config
    COLORS_FILE="${CONFIG_DIR}"/colors
    BACKUP_DIR=""
    #每次从原始文件里面缓存多少行(默认1000行)
    CACHE_LINES_NUMBER=0
    #每次打印多少行(默认10行)
    SHOW_LINES_NUMBER=0
    #是否打印行号(默认开启)
    ENABLE_LINE_NUMBER=0
    #是否彩色打印(默认开启)
    ENABLE_COLOR=0

    #存放书籍以及数据库文件的目录
    ROOT_DIR="${HOME}"/.tube-top
    BOOKS_DIR="${ROOT_DIR}"/books
    CACHE_DIR="${ROOT_DIR}"/cache

    #数据库文件(~/.tube-top/tube_top)的格式
    TUBE_TOP="${ROOT_DIR}"/tube_top

    #messages
    MSG_NO_READING_BOOK=$(
        cat << EOF
error: there are no books currently being read
usage: you can execute the following command to set the book you want to read:
tube_top.sh -p title
EOF
    )
fi

#第1列
#TITLE=""
#第2列
#ALIAS="none"
#第3列
#READING=false
#第4列:原始文件的总行数
#ORIGINAL_TOTAL_LINES=0
#第5列:在原始文件中,下次从哪一行开始读
#ORIGINAL_NEXT_LINE=1
#第6列:缓存文件的总行数
#CACHE_TOTAL_LINES=0
#第7列:在缓存文件中,下次从哪一行开始读
#CACHE_NEXT_LINE=1
#第8列:是否已经读完了(没有可打印的了)
#FINISH=false
#第9列:这本书是否曾经读完过
#EVER_FINISHED=false
