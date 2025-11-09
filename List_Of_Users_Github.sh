#!/bin/bash

# Ensure required programs are installed
for cmd in curl jq; do
    if ! command -v $cmd &>/dev/null; then
        echo "Error: '$cmd' is not installed. Please install it to proceed."
        exit 1
    fi
done

# Usage help
function show_usage {
    echo "Usage: $0 <repo_owner> <repo_name>"
    echo "Environment variables:"
    echo "  GITHUB_USERNAME - your GitHub username"
    echo "  GITHUB_TOKEN    - your personal access token"
    exit 2
}

# Require two arguments for owner and repo
if [[ $# -ne 2 ]]; then
    show_usage
fi

REPO_OWNER="$1"
REPO_NAME="$2"

# Load credentials from env or prompt for them
USERNAME="${GITHUB_USERNAME:-}"
TOKEN="${GITHUB_TOKEN:-}"

if [[ -z "$USERNAME" ]]; then
    read -rp "Enter your GitHub username: " USERNAME
fi

if [[ -z "$TOKEN" ]]; then
    read -rsp "Enter your GitHub personal access token: " TOKEN
    echo
fi

API_URL="https://api.github.com"

function github_api_get {
    local endpoint="$1"
    local url="${API_URL}/${endpoint}"
    http_code=$(curl -s -o response.tmp -w "%{http_code}" -u "${USERNAME}:${TOKEN}" "$url")
    if [[ $http_code -ne 200 ]]; then
        echo "GitHub API request failed with HTTP code $http_code."
        cat response.tmp
        rm -f response.tmp
        exit 3
    fi
    cat response.tmp
    rm -f response.tmp
}

function list_users_with_read_access {
    local endpoint="repos/${REPO_OWNER}/${REPO_NAME}/collaborators"
    collaborators=$(github_api_get "$endpoint" | jq -r '.[] | select(.permissions.pull == true) | .login')
    if [[ -z "$collaborators" ]]; then
        echo "No users with read access found for ${REPO_OWNER}/${REPO_NAME}."
    else
        echo "Users with read access to ${REPO_OWNER}/${REPO_NAME}:"
        echo "$collaborators"
    fi
}

echo "Listing users with read access to ${REPO_OWNER}/${REPO_NAME}..."
list_users_with_read_access
