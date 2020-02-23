#!/bin/sh

# add user to sudoers with no password option

c_user="$(whoami)"
sudoer_conf="/etc/sudoer"

usage() {
	echo ""
	echo "Usage : $0 [username]"
	echo "(NOTE : If username is blank, set sudoer to current user.)"
	exit 0
}
err_message(){
	>&2 echo "$1"
}

user_input(){
	read -r "$1" user_var
	echo "$user_var"
}

trap "echo \"Cancled.\";QUIT=1" 2

case $1 in
	-h|--help)
		usage
	;;
esac

if [ ! -z "$1" ];
then
	c_user="$1"
	id "$c_user" >/dev/null 2>&1

	if [ $? -ne 0 ];
	then
		err_message "'$c_user' does not exists."
		usage
		exit 1
	fi
fi

if [ "$c_user" = "root" ];
then
	err_message "'root' is not need." 
	exit 1
fi

while [ -z "$sudoer_conf" ] || [ -e "$sudoer_conf" ];
do
	echo "Cannot find sudoer config file at '$sudoer_conf'. Please input config file location."
	echo "(NOTE : If you didn't change configuration, press enter.)"
	read -p "Location : " sudoer_conf
done

target_file=""
if [ ! -z "$sudoer_conf" ];
then
	target_file="$(sudo grep "^includedir" /etc/sudoers | tail -1 | awk '{print $2}')"
	if [ -z "$target_file" ];
	then
		target_file="/etc/sudoers.d/"
	fi
fi

if [ ! -e "$target_file" ];
then
	sudo mkdir -p "$target_file"
	if [ $? -ne 0 ];
	then
		err_message "'$target_file' is not exists or"
		exit 1
	fi
fi

target_file="$target_file""$c_user"
if [ ! -e "$target_file" ];
then
	sudo touch "$target_file"
	if [ $? -ne 0 ];
	then
		err_message "Cannot create new file to '$target_file'"
		exit 1
	fi
	echo "$c_user ALL=NOPASSWD: ALL" | sudo tee -a $target_file >> /dev/null
else
	sudo sed -e "s/^$c_user .*/$c_user ALL=NOPASSWD: ALL/" $target_file 
fi

if [ $? -ne 0 ];
then
	err_message "Cannot make sudoer file."
	exit 1
fi

echo "Add '$c_user' no password option to '$target_file'"



