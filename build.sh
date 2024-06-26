#!/usr/bin/env bash

if [[ ! -d .git ]]; then
    echo "Run me from the repository root."
    exit
fi

# Read in our snippets for use with envsubst later on
__HEAD__=$(<templates/head.html)
export __HEAD__

# For the master posts list on the main page
unsorted_posts=()

# Generate the posts and the posts list
for post in site/posts/*.md; do
    name=$(basename "${post%.md}") # Trim path and .md extension
    date="${name%%_*}" # Trim after first underscore
    title="$(head -n 1 "$post")"

    __CONTENT__=$(lowdown --html-no-skiphtml --html-no-escapehtml "$post")
    export __CONTENT__

    post_dir="site/posts/${name}"
    [[ ! -d "$post_dir" ]] && mkdir "$post_dir"
    envsubst <templates/post.html >"${post_dir}/index.html"

    unsorted_posts+=("<tr><td class=\"posts-date\">${date}</td><td class=\"posts-title\"><a href=\"posts/${name}/\">${title}</a></td></tr>")
done

# Sort the posts into $__POSTS__
__POSTS__=$(printf '%s\n' "${unsorted_posts[@]}" | sort -r)
export __POSTS__

# Generate the main page with the master posts list
envsubst <templates/index.html >site/index.html

# Generate the nav pages
for page in site/*.md; do
    __CONTENT__=$(lowdown "$page")
    export __CONTENT__

    envsubst <templates/post.html >"${page%.md}.html"
done
