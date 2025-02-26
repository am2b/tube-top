#!/usr/bin/env bash

SELF_ABS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "${SELF_ABS_DIR}"/global_variables.sh
source "${SELF_ABS_DIR}"/impl.sh

set_alias() {
    alias_name="${1}"

    BOOK_NAME=$(_get_the_reading_book_name)
    if [[ -z $BOOK_NAME ]]; then
        echo "${msg_no_reading_book}"
        exit 1
    fi

    sed -i -E "/^${BOOK_NAME},/s/^([^,]+,)[^,]+/\1${alias_name}/" "${TUBE_TOP}"

    exit 0
}
