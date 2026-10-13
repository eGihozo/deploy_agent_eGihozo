#!/bin/env bash

script_path=$(realpath "$0")
script_dir=$(dirname "$script_path")
template_dir="$script_dir/templates"

cd "$script_dir" || exit 1

project_dir=""
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

read_int(){
	local prompt=$1 default=$2 min=$3 max=$4 val
	while true; do 
		read -r -p "$prompt [default $default]: " val

		if [[ -z "$val" ]]; then
			val=$default
		fi

	if [[ ! "$val" =~ ^[0-9]+$ ]]; then
		echo "This is not a whole number,try again!"
	elif (( 10#$val < $min || 10#$val > $max )); then
	       echo "please enter a number between $min and $max "
       else 
	       num=$((10#$val))
return
	fi
done

}

ask_project_name(){
	local project_name
	echo "The project folder could be named attendance_tracker_<name>"
	read -r -p "ENTER THE PROJECT NAME: " project_name


	if [[ -z "$project_name" ]]; then
		fail "Type the project name according to given example"
	fi

	if [[ ! "$project_name" =~ ^[A-Za-z0-9_-]+$ ]]; then
	fail "Names can only contain letters,numbers,- or _"
	fi

	target="attendance_tracker_${project_name}"
	info "Project folder will be: $target"

}

