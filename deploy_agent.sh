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

names=("Alice Kayitesi" "Karenzi Bob" "Nyirmavuko Carol" "Ishimwe David" "kemugisha"
       "Kayitare Frank" "Bajeneza Grace" "Mugisha Henry" "Rugwiro Taylor" "Jack kalisa"
       "Karen Bugingo" "Leo pierre" "Mia Kayitana" "Shema Noah" "Busingye Olivia"
       "Paul Kagame" "Bajeneza Sonia" "Kiberinka Rose" "Sam Jakin" "Keza Tina")


# handle_interrupt: runs when the user presses Ctrl+C or Ctrl+Z during deployment.

handle_interrupt() {

	local zip_name="${project_dir}_archive.zip"

	trap '' INT TSTP
	echo
	echo" Deployment Interrupted"

	if [[ -z "$project_dir" || ! -d "$project_dir" ]]; then
		info " No project folder exists yet"
		echo "session closed!"
		exit 130
	fi

	if zip -rq "$zip_name" "$PROJECT_DIR"; then
		ok "Archive created: $zip_name"
	else
		echo "ERROR: Archive failed, could not create the zip file."
		echo " Folder '$project_dir' was kept,nothing lost"
		exit 130
	fi

	info "Removing unfinished folder $project_dir ..."

	if rm -rf "$project_dir"; then
		ok "Incomplete directory '$project_dir' removed"
	else 
		echo "[ERROR] could not remove '$project_dir'."
	fi

	echo "Session closed"
	exit 130

}

#deploying


preflight_checks(){

	if ! command -v python3 > /dev/null; then
		echo "python is not installed"
		exit 1
	fi

	if ! command -v zip > /dev/null; then
		echo "zip is not installed."
		exit 1
	fi
	echo "Python version : $(python3 --version)"
	
	local file
	for file in attendance_checker.py assets.csv config.json; do
		if [[ ! -f "$template_dir/$file" ]]; then
			fail "templates/$file is missing , try again"
		fi
	done
	ok "All 3 template files were found."
}

create_structure(){

	local answer

	if [[ -d "$target" ]]; then
		read -r -p "$target already exists, Delete and start? (y/n): " answer
		if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
			rm -rf "$TARGET" || fail "Could not delete $TARGET (permission denied?)."
			info "Old folder deleted"


		else 
			fail "Stopped. $TARGET already exists and was not changed."
		fi
	fi

	mkdir -p "$target/helpers" "$target/reports" || fail "couldnot create folder"
	project_dir="$target"
	ok "$target was created with helpers and reports"
}



copy_core_files(){

	cp "$template_dir/attendance_checker.py" "$target/attendance_checker.py" || fail "could not copy attendance_cheker file"
	 
	cp "$template_dir/config.json" "$target/helpers/" || fail "could not config.json file"

}

build_roster() {
	local choice
	local roster_file="$target/helpers/assets.csv"
	local config_file="$target/helpers/config.js"
	local template roster="$template_dir/assets.csv"

	echo "How do you want to build your student roster?"
	echo "A. Copying students from template"
	echo "B. Generating new students"

	while true; do
		read -r -p "choose A or B: " choice
		if [[ "$choice" == "A" || "$choice" == "a" ]]; then
			choice="A"
			break
		elif [[ "$choice" == "b" || "$choice" == "B" ]]; then
			choice="B"
			break;
		else
			echo " Please Enter A or B"
		fi 
	done
	if [[ "$choice" == "A" ]]; then
		local lines_in_template=$(grep -c . "$template_roster")
		local max_students=$((lines_in_template - 1))

		read_int "How many students are there to copy (1-$max_students)" "$max_students" 1 "$max_students"

head -n $((num + 1)) "$template_roster" > "$roster_file" || fail "Could not write the roster."
ok "Copied $num students from the template"
 

else

	local count name email number
	 read-int "How many students (1-${#names[@]}" 10 1 "${#names[@]}"
	 count=$num
	 echo "Email, Names, Attendance count, Count, Absence count" >"$roster_file" || fail "couldn't write the roster"

	 number=0
	 while [[ $number -lt $count ]]; do
		name="${names[$number]}"
		email=$(echo "$name" | tr 'A-Z' 'a-z.')@student.com
	       echo "$email,$name,0,0" >> "$roster_file"
	       number=$((number = 1))
       done

      sed -i -E 's/("total_sessions": *)[0-9]+/\11/' "$config_file" || fail "Could not update config.json."

ok "Generate $count students and total-sessions set to 1."
	fi

}

set_permissions(){

	local app-file="$target/attendance_checker.py"
	local config_file="$target/helpers/config.json"
	
	chmod +x "$app_file" || fail "Could not makeattendance_checker.p,y executable"

	chmod 600 "config_file" || fail "Could not lock config.json"
	ok "config.json is private"

	echo "Here is what the permissions look like now:"
	ls -l "$app_file" "$config_file"
}


update_thresholds(){

local answer warning failure 
local config_file="$target/helpers/config.json"

read -r -p "Do you want to change attendance alert thresholds? (y/N): " answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
	info "we are keeping the default thresholds"
	return
fi

while true; do
	read_int "New warning thresholdin percentage" 75 0 100
	warning=$num

	read_int "New failure threshold" 50 0 100
	failure=$num

	if [[ $failure -ge $warning ]]; then
		echo "failure must be lower than warning , try again"
	else 
		break
	fi 
done
sed -i "s/\"warning\": *[0-9]*/\"warning\": $warning/" "$config_file" || fail "Could not update warning."
  sed -i "s/\"failure\": *[0-9]*/\"failure\": $failure/" "$config_file" || fail "Could not update failure."

 chmod 600 "$config_file"
 ok "Thresholds updated:"
 grep -E '"warning"|"failure"' "$config_file"
}

deploy(){
preflight_checks
ask_project_name

trap handle_interrupt INT TSTP

create_structure
install_app_files
build_roster
set_permissions
update_thresholds

trap - INT TSTP

OK "Deployment complete"
run_app "$target"

}

run_app(){
local folder=$1

if [[ ! -d "$folder" ]]; then
	fail "$folder does not exist, deploy first"
fi

if [[ ! -f "$folder/attendance_checker.py" ]]; then
fail " $folder is missing ateendance_checker.py"
fi

info "Lets start the app"
(cd "$folder" && python3 attendance_checker.py)
}

