#!/bin/bash
# setup script for dependencies directory

# detect OS (mac or linux)
OS="$(uname)"

echo "Setting up dependencies..."

check_and_install() {
    local cmd="$1";
    local pkg="$2";
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$cmd not found, installing..."
        if [[ "$OS" == "Darwin" ]]; then
            if command -v brew >/dev/null 2>&1; then
                brew install "$pkg"
            else
                echo "Homebrew not installed; please install $cmd manually."
                exit 1
            fi
        else
            # assume linux and apt-get available
            if command -v apt-get >/dev/null 2>&1; then
                sudo apt-get update && sudo apt-get install -y "$pkg"
            elif command -v yum >/dev/null 2>&1; then
                sudo yum install -y "$pkg"
            else
                echo "Package manager not detected; install $cmd manually."
                exit 1
            fi
        fi
    else
        echo "$cmd already installed."
    fi
}

# check for required tools
check_and_install git git
check_and_install docker docker
check_and_install node node
