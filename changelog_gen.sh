#!/bin/bash

source helpers/funclib.sh

usage ()
{
cat <<-EOF
$(basename "$0") OPTIONS
Options List:
=============
    -h				This help message
    -o	<Old ref or version>	Specify the first git ref to start the changelog ( Cannot contain '/' )
    -n	<New ref or version>	Specify the second git ref to end the changelog ( Cannot contain '/' )
    [-u]  <Base URL>            Specify the base url for the generated commit link
    [-f]  <filter>              Used if you want to limit the scope of the changelog to sub-dir

This script will attempt to create a changelog in Markdown between the given git refs
EOF
}


changelog() {
  local oldref=$1
  local newref=$2
  local apps=${3}
  local repo_url=${4:-"https://github.com/slamont/misc-tools/commit/"}
  local changelog_tmp_file=${5:-"/tmp/CHANGELOG_${oldref}_${newref}.md"}
  print_info "Creating changelog file"
  echo -e "# Changelog\n" > ${changelog_tmp_file}
  echo -e "## ${oldref^^} to ${newref^^}\n" >> ${changelog_tmp_file}
  echo -e "### Changes for [${apps}]\n" >> ${changelog_tmp_file}
  echo "| Commits | Committer | Message |" >> ${changelog_tmp_file}
  echo "| --- | --- | --- |" >> ${changelog_tmp_file}
    git log \
     --format="| [%h](${repo_url}%H) | %ce | %s |" \
     --grep='^.*\[maven-release-plugin\]' \
     --grep='^.*\[Gradle Release Plugin\]' \
     --grep='^.*Merge remote-tracking branch' \
     --grep='^.*Merged in ' \
     --invert-grep \
     ${oldref}..${newref} \
     -- ${apps} >> ${changelog_tmp_file}
  print_info "Created changelog file [ ${changelog_tmp_file} ]"
}

if [ $# -lt 2 ]; then
  usage
  exit 2
fi
generate_line
print_empty
print_info "Changelog generator for git revisions"
print_empty
generate_line

while getopts "ho:n:u:f:" OPTION; do
  case $OPTION in
    o)
      print_info "Old Ref: $OPTARG"
      OLD_VERSION=$OPTARG
      ;;
    n)
      print_info "New Ref: $OPTARG"
      NEW_VERSION=$OPTARG
      ;;
    u)
      print_info "Commits base url: $OPTARG"
      REPO_URL=$OPTARG
      ;;
    f)
      print_info "Filtering for [$OPTARG]"
      APP_FILTER=$OPTARG
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ -z $OLD_VERSION || -z $NEW_VERSION ]]; then
  print_err 'You did not provide either an old ref or a new one. Both are required'
  usage
  exit 1
fi

REPO_URL=${REPO_URL:-"http://example.com/commits/"}
APP_FILTER=${APP_FILTER:-"./"}

changelog $OLD_VERSION $NEW_VERSION "$APP_FILTER" $REPO_URL ./changelog_${OLD_VERSION}__${NEW_VERSION}.md
