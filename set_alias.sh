#!/usr/bin/env bash

set_alias() {
    check_parameters 1 -- "$@" || exit $?

    local alias
    alias="${1}"

    local title
    if ! title=$(_get_title_of_the_reading_book); then
        echo "error:get title failed in function:set_alias" >&2
        exit 1
    fi

    _update_field_in_tube_top "${title}" "ALIAS" "${alias}"
}
