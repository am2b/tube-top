#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

backup() {
    if [[ -z "${backup_dir}" ]]; then
        echo "error:read backup dir from config failed"
        exit 0
    fi

    if [[ ! -d "${backup_dir}" ]]; then
        mkdir -p "${backup_dir}"
    fi

    local TIMESTAMP
    local backup_name
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_name="tube_top_${TIMESTAMP}"

    cp "${TUBE_TOP}" "${backup_dir}"/"${backup_name}"

    #删除旧的备份文件
    local keep_num
    local backup_counts
    keep_num=25
    #计算文件数量
    backup_counts=$(find "${backup_dir}" -name ".DS_Store" -prune -o -type f -print | wc -l)
    if ((backup_counts > keep_num)); then
        find "${backup_dir}" -name ".DS_Store" -prune -o -type f -printf "%T@ %p\0" |
            sort -zn |
            head -z -n "$((backup_counts - keep_num))" |
            cut -z -d ' ' -f2- |
            while IFS= read -r -d '' file; do
                rm -f "${file}"
            done
    fi

    exit 0
}
