#!/bin/bash

set -o errexit  # Exit on error
set -o nounset  # Trigger error when expanding unset variables

function realpath
{
    [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

SCRIPT_PATH="$(realpath ""$0"")"
PATCH_PATH="${SCRIPT_PATH/sh/patch}"
BASE_DIR="$HOME/morningstar"

function force
{
    echo "Check failed: $1"
    if [[ -z "$DO_FORCE" ]]
    then
        echo "Use --force to ignore checks"
        exit 1
    fi
}

function check
{
    [[ $(cat /etc/debian_version) == 7.* ]] || force "Debian 7 (wheezy) required"

    [[ -x "$(which git)" ]] || force "git not found. Please check that it is istalled and in PATH"

    #[[ -f "$PATCH_PATH" ]] || force "Patch file not found"
}

function reset
{
    sudo apt-get update || force "apt-get update failed"

    sudo apt-get -y install build-essential libssl-dev libdb++-dev libboost-all-dev libqrencode-dev libminiupnpc-dev || force "apt-get install failed"

    rm -rf "$BASE_DIR"
    mkdir -p "$BASE_DIR"
    cd "$BASE_DIR"

    git clone https://github.com/dzimbeck/morningstar
    
    #cd src/leveldb
    #chmod 755 build_detect_platform
    #make
    #make libmemenv.a
    cp LevelDB/libleveldb.a src/leveldb/libleveldb.a
    cp LevelDB/libmemenv.a src/leveldb/libmemenv.a
    #cd morningstar
    #git am "$PATCH_PATH"
}

function build
{
    cd "$HOME/morningstar/morningstar/src"
    
    make STATIC=1 USE_UPNP=1 -f makefile.unix
    
    strip morningstard
}

function help
{
    echo "Use:"
    echo "$0 [ --help ] [ --force ] [ --reset ] [ --build ]"
}

DO_HELP=
DO_FORCE=
DO_RESET=
DO_BUILD=

for arg in "$@"
do
    if [[ "$arg" == "--help" ]]
    then
        DO_HELP=1
    elif [[ "$arg" == "--force" ]]
    then
        DO_FORCE=1
    elif [[ "$arg" == "--reset" ]]
    then
        DO_RESET=1
    elif [[ "$arg" == "--build" ]]
    then
        DO_BUILD=1
    else
        echo "Unknown argument: $arg"
        help
        exit 1
    fi
done

if [[ -z "$DO_RESET" && -z "$DO_BUILD" || -n "$DO_HELP" ]]
then
    help
    exit 0
fi

check

if [[ -n "$DO_RESET" ]]
then
    reset
fi

if [[ -n "$DO_BUILD" ]]
then
    build
fi

if [[ -z "$DO_FORCE" ]]
then
    echo "Success!"
fi
