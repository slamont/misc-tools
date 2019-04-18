#!/bin/bash

VERSION=$1
SEARCH_BASEPATH=$2

_find_closest_datadir() {
    local version="${1:?"You must provide the version to search for"}"
    local search_basepath="${2:?"You must provide the base directory to search in"}"

    local found_dir=
    local old_pattern=

    dir_count=$(/bin/ls -1 "${search_basepath}" | wc -l)
    while [[ -z $found_dir ]] && [[ ${old_pattern} != ${version} ]]
    do
      found_dir=$(find "$search_basepath" -maxdepth 1 -name "${version}" | sort -rn |head -n 1)
      old_pattern="${version}"
      if [[ -z $found_dir ]]; then
        version=${version%[.|-]*}
        found_dir=$(find "$search_basepath" -maxdepth 1 -name "${version}*" | sort -rn |head -n 1)
      fi
    done
    [[ -z $found_dir ]] && exit 2
    echo "${found_dir}"

}

datadir=$(_find_closest_datadir $VERSION $SEARCH_BASEPATH)
echo "Closest datadir found for the given version [${VERSION}] in [${SEARCH_BASEPATH}] is : [${datadir}]"
