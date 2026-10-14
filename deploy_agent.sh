#!/usr/bin/env bash

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
	echo "[ERROR] $*" >&2;
       	exit 1;
}

read_int(){
	local prompt=$1 default=$2 min=$3 max=$4 val
	while true; do 
		read -r -p "$prompt [default $default]: " val || fail "Input closed"

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
       "Paul Ndoba" "Bajeneza Sonia" "Kiberinka Rose" "Sam Jakin" "Keza Tina")



handle_interrupt() {

	local zip_name="${project_dir}_archive.zip"

	trap '' INT TSTP
	echo
	echo "Deployment Interrupted"

	if [[ -z "$project_dir" || ! -d "$project_dir" ]]; then
		info " No project folder exists yet"
		echo "session closed!"
		exit 130
	fi

	if zip -rq "$zip_name" "$project_dir"; then
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
		echo "[ERROR] could not remove '$project_dir'.">&2
	fi

	echo "Session closed"
	exit 130

}

#deploying


preflight_checks(){

	if ! command -v python3 > /dev/null 2>&1; then
		echo "python is not installed"
		exit 1
	fi

	if ! command -v zip > /dev/null 2>&1; then
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

	helpers_name="Helpers"
}

create_structure(){

	local answer

	if [[ -d "$target" ]]; then
		read -r -p "$target already exists, Delete and start? (y/n): " answer
		if [[ "$answer" == "y" || "$answer" == "Y" ]]; then
			rm -rf "$target" || fail "Could not delete $target (permission denied?)."
			info "Old folder deleted"


		else 
			fail "Stopped. $target already exists and was not changed."
		fi
	fi

	mkdir -p "$target/$helpers_name" "$target/reports" || fail "couldnot create folder"
	project_dir="$target"
	ok "$target was created with helpers and reports"
}



copy_core_files(){

	cp "$template_dir/attendance_checker.py" "$target/attendance_checker.py" || fail "could not copy attendance_cheker file"
	 
	cp "$template_dir/config.json" "$target/$helpers_name/" || fail "could not copy config.json file"

}

build_roster() {
local choice
    local roster_file="$target/$helpers_name/assets.csv"
    local config_file="$target/$helpers_name/config.json"
    local template_roster="$template_dir/assets.csv"

    echo "How do you want to build your student roster?"
    echo "  A. Copy students from the template"
    echo "  B. Generate new students"

   
    while true; do
        read -r -p "Choose A or B: " choice || fail "Input closed."
        case "$choice" in
            A|a) choice="A"; break ;;
            B|b) choice="B"; break ;;
            *)   echo "Please enter A or B." ;;
        esac
    done

    if [[ "$choice" == "A" ]]; then
 
        local lines_in_template max_students
        lines_in_template=$(grep -c . "$template_roster")
        max_students=$((lines_in_template - 1))   # minus the header row

        if (( max_students < 1 )); then
            fail "templates/assets.csv has no student rows."
        fi

        read_int "How many students to copy (1-$max_students)" "$max_students" 1 "$max_students"
        head -n $((num + 1)) "$template_roster" > "$roster_file" \
            || fail "Could not write the roster."

        
        sed -i -E 's/("total_sessions": *)[0-9]+/\15/' "$config_file" \
            || fail "Could not update total_sessions."

        ok "Copied $num students from the template (total_sessions = 5)."
    else
      
        local count name email i
        read_int "How many students (1-${#names[@]})" 10 1 "${#names[@]}"
        count=$num

        echo "Email,Names,Attendance Count,Absence Count" > "$roster_file" \
            || fail "Could not write the roster."

        for (( i = 0; i < count; i++ )); do
            name="${names[$i]}"
           
            email="$(echo "$name" | tr '[:upper:] ' '[:lower:].')@student.com"
            echo "$email,$name,0,0" >> "$roster_file"
        done
        sed -i -E 's/("total_sessions": *)[0-9]+/\11/' "$config_file" \
            || fail "Could not update total_sessions."

        ok "Generated $count students (total_sessions = 1)."
    fi

}

set_permissions(){

	local app_file="$target/attendance_checker.py"
	local config_file="$target/$helpers_name/config.json"
	
	chmod +x "$app_file" || fail "Could not makeattendance_checker.p,y executable"

	chmod 600 "$config_file" || fail "Could not lock config.json"
	ok "config.json is private"

	echo "Here is what the permissions look like now:"
	ls -l "$app_file" "$config_file"
}


update_thresholds(){

local answer warning failure 
local config_file="$target/$helpers_name/config.json"

read -r -p "Do you want to change attendance alert thresholds? (y/N): " answer

if [[ "$answer" != "y" && "$answer" != "Y" ]]; then
	info "we are keeping the default thresholds (warning=75 , failure=50)"
	return
fi

while true; do
	read_int "New warning threshold in percentage" 75 0 100
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
	
project_dir=""	
preflight_checks
ask_project_name
trap handle_interrupt INT TSTP

create_structure
copy_core_files
build_roster
set_permissions
update_thresholds

trap - INT TSTP

ok "Deployment complete"
run_app "$target"

}

run_app(){
local folder=$1

if [[ ! -d "$folder" ]]; then
	fail "$folder does not exist, deploy first"
fi

if [[ ! -f "$folder/attendance_checker.py" ]]; then
fail " $folder is missing attendance_checker.py"
fi

info "Lets start the app"
(cd "$folder" && python3 attendance_checker.py)
}

archive_logs(){

	local saved=0 timestamp log_name original copy
        echo "First saving a copy of attendance logs."
	ask_project_name

	if [[ ! -d "$target" ]]; then
		fail "i could not find $target , deploy it first"
	fi

	 timestamp=$(date +%Y%m%d_%H%M%S)

	 mkdir -p "$target/archives/attendance" "$target/archives/absent" || fail "couldn't create the archive folders"

	 for log_name in attendance absent; do 
		 original="$target/reports/${log_name}.log"
		 copy="$target/archives/${log_name}/${log_name}_${timestamp}.log"

		 if [[ ! -f "$original" ]]; then
			 info " there is no ${log_name}.log yet" 
			 continue
		 fi

		 if cp "$original" "$copy"; then
			 ok "Saved $log_name.log to $copy"
			 saved=$((saved + 1))
		 else
			 echo "I couldn't save $log_name.log" >&2
		 fi
	 done

	 if [[ $saved -eq 0 ]]; then
		 info "Nothing saved, run the application first and try againq"
	 else
		 ok "DONE"
		 fi
	 }
 show_menu(){

 local choice

 while true; do
	 echo
	 echo " Attendance Tracker Deploy Agent "
	 echo "1) Deploy a new project"
	 echo "2) Run a project"
	 echo "3) Archive logs"
	 echo "4) Exit"

		 read -r -p "What would you like to?(choose from 1-4): " choice

	 case "$choice" in
		 1) deploy ;;
		 2) ask_project_name
			 run_app "$target" ;;
		 3) archive_logs ;;
		 4) echo "Bye!!" 
			 exit 0 ;;
		 *) echo "Choose a number from 1 to 4" ;;
	 esac
 done
}


case "$1" in 
	--deploy)
		deploy
		;;
	--run)
		ask_project_name
		run_app "$target"
		;;
	--archive)
		archive_logs
		;;
	"")
		show_menu
		;;
	*)
		echo "Unknown option: $1"
		echo "Usage: $0 [--deploy | --run | --archive]"
		exit 1
		;;
esac


