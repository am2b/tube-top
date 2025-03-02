#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh

delete_old_files() {
    local dest_dir
    local keep_num
    dest_dir=$(realpath "${1}")
    keep_num="${2}"

    exclude_files_dirs=(".DS_Store" ".git")
    prune_expr=()
    for e in "${exclude_files_dirs[@]}"; do
        prune_expr+=(-name "$e" -prune -o)
    done

    local find_counts
    #递归搜索
    find_counts=$(find "${dest_dir}" \( "${prune_expr[@]}" -false \) -o -type f -print | wc -l)
    if ((find_counts > keep_num)); then
        find "${dest_dir}" \( "${prune_expr[@]}" -false \) -o -type f -printf "%T@ %p\0" |
            sort -zn |
            head -z -n "$((find_counts - keep_num))" |
            cut -z -d ' ' -f2- |
            while IFS= read -r -d '' file_to_be_deleted; do
                trash "${file_to_be_deleted}"
            done
    fi
}

backup() {
    if [[ -z "${backup_dir}" ]]; then
        echo "error:read backup dir from config failed"
        exit 1
    fi

    if [[ ! -d "${backup_dir}" ]]; then
        mkdir -p "${backup_dir}"
    fi

    if [[ ! -d "${HOME}"/.trash ]]; then
        echo "error:no trash can found"
        exit 1
    fi

    local TIMESTAMP
    local backup_name
    TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
    backup_name="tube_top_${TIMESTAMP}"

    cp "${TUBE_TOP}" "${backup_dir}"/"${backup_name}"

    #删除旧的备份文件
    delete_old_files "${backup_dir}" 25
}
