#!/usr/bin/env bash

set -e

ghprgen::usage() {
cat <<-EOH
Usage:
  $(basename $0) [-h] [-t title] <org> <repo> <base> <head>

  arguments:
    org : Creation target GitHub organization name
    repo: Creation target GitHub repository name
    base: Pull request source branch
    head: Pull request target branch

  envionment:
    GHPRGEN_GITHUB_API_TOKEN: GitHub personal api token

  options:
    -t title: pull reuqest title (default: "Merge <base> into <head>")
    -h      : show usage

  example:
    $0 yasuhrioki gh-pr-gen.sh yasuhiroki:master feature-branch
    GHPRGEN_GITHUB_API_TOKEN=xxxxxxxxxxx $0 yasuhrioki gh-pr-gen.sh yasuhiroki:master feature-branch
EOH
}

ghprgen::required_check() {
  local err=0
  for _c in git jq curl
  do
    which ${_c} >/dev/null || err=1
  done
  return $err
}

ghprgen::gh::api::endpoint_url() {
  echo "https://api.github.com"
}

ghprgen::gh::api::pulls() {
  local org="${1}"
  local repo="${2}"
  : ${org:?}
  : ${repo:?}
  echo "$(ghprgen::gh::api::endpoint_url)/repos/${org}/${repo}/pulls"
}

ghprgen::gh::authrization_header() {
  if [ ! -z "${GHPRGEN_GITHUB_API_TOKEN}" ]; then
    echo "Authorization: token ${GHPRGEN_GITHUB_API_TOKEN}"
  fi
}

ghprgen::print_pr_header() {
  echo "# Releases"
}

ghprgen::print_pr_body() {
  local base="${1}"
  local head="${2}"
  local pulls_api="${3}"
  : ${base:?}
  : ${head:?}
  : ${pulls_api:?}

  local req_header="$(ghprgen::gh::authrization_header)"

  git log --pretty=format:"%s" --reverse --merges ${base}..${head/*:} \
    | \
    cut -d' ' -f4 \
    | \
    tr -d '#' \
    | \
    xargs -I{} sh -c "curl -sS ${req_header:+-H "${req_header}"} '${pulls_api}'{} | jq -r '.title' | sed 's/$/ #{}/g'" \
    | \
    sed 's/^/- [x] &/g'
}

ghprgen::get_pr_url() {
  local base="${1}"
  local head="${2}"
  local pulls_api="${3}"
  : ${base:?}
  : ${head:?}
  : ${pulls_api:?}

  local req_header="$(ghprgen::gh::authrization_header)"

  curl -sS ${req_header:+-H "${req_header}"} "${pulls_api}" -G -d "state=open" --data-urlencode "base=${base}" --data-urlencode "head=${head}" | jq -r '.[0].url'
}

# stdin: pull request body
ghprgen::cmd::create_pr() {
  local base="${1}"
  local head="${2}"
  local title="${3}"
  local pulls_api="${4}"
  : ${base:?}
  : ${head:?}
  : ${title:?}
  : ${pulls_api:?}

  local req_header="$(ghprgen::gh::authrization_header)"

  jq -sR '{title: "'"${title}"'" , body: ., base: "'"${base}"'", head: "'"${head}"'"}' \
    | \
    curl -XPOST -sS ${req_header:+-H "${req_header}"} ${pulls_api} -d @-
}

# stdin: pull request body
ghprgen::cmd::update_pr() {
  local base="${1}"
  local head="${2}"
  local title="${3}"
  local pr_url="${4}"
  : ${base:?}
  : ${head:?}
  : ${title:?}
  : ${pr_url:?}

  local req_header="$(ghprgen::gh::authrization_header)"

  jq -sR '{title: "'"${title}"'" , body: ., base: "'"${base}"'"}' \
    | \
    curl -XPATCH -sS ${req_header:+-H "${req_header}"} ${pr_url} -d @-
}

ghprgen::main() {
  org="$1"
  repo="$2"
  base="$3"
  head="$4"

  : ${org:?}
  : ${repo:?}
  : ${base:?}
  : ${head:?}

  (( $(git log --pretty=format:"%s" --reverse --merges ${base}..${head/*:} | wc -l) > 0 )) || {
    echo "Don't have merge commit"
    return 1
  }

  local pulls_api="$(ghprgen::gh::api::pulls ${org} ${repo})"
  local title="Merge ${head} into ${base}"

  local pr_url="$(ghprgen::get_pr_url ${base} ${head} ${pulls_api})"
  if [ -z "${pr_url}" -o "${pr_url}" = "null" ]; then
    {
      ghprgen::print_pr_header
      echo
      ghprgen::print_pr_body ${base} ${head} ${pulls_api}
    } | ghprgen::cmd::create_pr ${base} ${head} "${title}" ${pulls_api}
  else
    {
      ghprgen::print_pr_header
      echo
      ghprgen::print_pr_body ${base} ${head} ${pulls_api}
    } | ghprgen::cmd::create_pr ${base} ${head} "${title}" ${pr_url}
  fi
}

(ghprgen::main $@) || {
  echo "Failed!"
  echo
  ghprgen::usage
}

