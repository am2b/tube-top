#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
#source "${SELF_ABS_DIR}"/impl.sh

#列出已经读完的书
list_finished_books() {
    #表示finish的true或false位于第7列
    sed -n '/^\([^,]*,\)\{6\}true/p' "${TUBE_TOP}" | cut -d',' -f1

    #仅查询,无需写入记录
    exit 0
}
