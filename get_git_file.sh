#!/bin/bash

version=1.0.3

usage=$(cat <<-EOF

Usage:
    $0 -f <git_file_path> [options]
    $0 --help
    $0 --version

Download individual files from GitHub private and public repos.

Options

    -f,  --git_file     File to download. Get the path from the web interface by clicking the 'Copy Path' button
    -o,  --output       Output file and path. [Optiona] Gets from the git_file if not specified
    -r,  --repo         Name of the repo you are trying to download from. Case-sensitive [Optional]
    -w, --owner         Name of the repo owner you are trying to download from. Case-sensitive [Optional]
    --help              Show this help.
    --version           Returns the version of this script

EOF
)

config_file="${HOME}/.get_git_file.conf"

urlencode() {
    # Usage: urlencode "string"
    local LC_ALL=C
    for (( i = 0; i < ${#1}; i++ )); do
        : "${1:i:1}"
        case "$_" in
            [a-zA-Z0-9.~_-:/:])
                printf '%s' "$_"
            ;;

            *)
                printf '%%%02X' "'$_"
            ;;
        esac
    done
    printf '\n'
}

function get_configs () {

if [ -f $config_file ]; then
    source ${config_file}
else
    echo "Config not found in file: ${config_file}"
    printf "\nCreating default config file . . .\n"
    printf "GIT_TOKEN=\nGIT_REPO=\nGIT_OWNER=\n" > $config_file
    chmod 640 $config_file
    printf "Default config file created at %s\n\n" $config_file
    source ${config_file}
fi

# Need the token before we try to download
if [ -z "$GIT_TOKEN" ]; then
    read -r -p "Enter your private Git Token: " GIT_TOKEN
    sed -i "s/^GIT_TOKEN.*/GIT_TOKEN=${GIT_TOKEN}/g" $config_file
fi

if [ -n "$file_repo" ]; then
    sed -i "s/^GIT_REPO.*/GIT_REPO=${file_repo}/g" $config_file
    GIT_REPO=$file_repo
else
    # User has not specified a repo so make sure setting in config is not empty
    if [ -z "$GIT_REPO" ]; then
        read -r -p "Enter the file REPO name: " GIT_REPO
        sed -i "s/^GIT_REPO.*/GIT_REPO=${GIT_REPO}/g" $config_file
    fi
fi

if [ -n "$file_owner" ]; then
    sed -i "s/^GIT_OWNER.*/GIT_OWNER=${file_owner}/g" $config_file
    GIT_OWNER=$file_owner
else
    # User has not specified a owner so make sure setting in config is not empty
    if [ -z "$GIT_OWNER" ]; then
        read -r -p "Enter the repo OWNER name: " GIT_OWNER
        sed -i "s/^GIT_OWNER.*/GIT_OWNER=${GIT_OWNER}/g" $config_file
    fi
fi

# Need to know what file name to save to
if [ -z "$output_file" ]; then
    output_file=$(basename "$git_file")
fi

dirname() {
    # Usage: dirname "path"
    local tmp=${1:-.}

    [[ $tmp != *[!/]* ]] && {
        printf '/\n'
        return
    }

    tmp=${tmp%%"${tmp##*[!/]}"}

    [[ $tmp != */* ]] && {
        printf '.\n'
        return
    }

    tmp=${tmp%/*}
    tmp=${tmp%%"${tmp##*[!/]}"}

    printf '%s\n' "${tmp:-/}"
}

if [ -d "$output_file" ]; then
    # Add trailing if needed
    [[ "${output_file}" != */ ]] && output_file="${output_file}/"; :

    output_file="${output_file}$(basename "$git_file")"

elif [[ $output_file == */ ]]; then
    echo "You appear to have specified an output directory that does not exist."
    echo "Check your output path/file or create the directory first."
    echo ""
    exit
fi

# Check the directory path is valid if it contains a "/"
if [[ $output_file == */* ]]; then
    output_dir=$(dirname "$output_file")

    if [ ! -d "$output_dir" ]; then
        echo "Directory $output_dir is not valid. Check and try again."
        echo ""
        exit
    fi

fi

git_file=$(urlencode "$git_file")

}

function get_file() {

# Now get the download url
repo_download_url=$(curl -s --header "Authorization: token $GIT_TOKEN" \
     --location "https://api.github.com/repos/${GIT_REPO}/${GIT_OWNER}/contents/${git_file}" | \
  awk '/download_url/ {print "" substr($2, 2, length($2)-3) ""}')

curl -H "Authorization: token $GIT_TOKEN" -H "Accept:application/vnd.github.v3.raw" "{$repo_download_url}" -o "$output_file"

printf "\n"
ls -lhA "$output_file"
printf "\nFinished\n"

}

while [ $# -ge 1 ]
do
    case "$1" in
        -f | --git-file)    git_file=$2;;
        -o | --output)      output_file=$2;;
        -r | --repo)        file_repo=$2;;
        -w | --owner)       file_owner=$2;;
        --version)          echo "$0 version: $version"; exit;;
        -*)                 echo "$usage"; exit;;
    esac
    shift
done

if [ -z "$git_file" ]; then
    echo "The Git File path to download is required. Specify it with '-f' or '--git-file'"
    echo "Use the 'Copy Path' button in the GitHub GUI to get the correct path when looking at the file"
    exit
fi

get_configs
get_file