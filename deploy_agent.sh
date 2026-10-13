#!/bin/env bash

script_path=$(realpath "$0")
script_dir=$(dirname "$script_path")
template_dir="$script_dir/templates"

cd "script_dir" || exit 1

project_idir=""
target=""
num=0

info(){
echo "[INFO]  $*";
}

ok() {
	echo "[ok] $*";
}

fail(){
	echo "[ERROR] $*" >&2; exit 1;
}
