#!/bin/sh

# Wipe disk by 'dd' command

basepath="$(dirname $0)"
tmp_path="$basepath/.tmp"

bs="4M"
src="/dev/./urandom"
cnt="1"

err_message(){
	>&2 echo "!!! $1"
}

_exit(){
	if [ -e "$tmp_path" ];
	then
		rm -rf $tmp_path
	fi
	exit "$1"
}

mkdir -p $tmp_path
if [ $? -ne 0 ];
then
	err_message "Cannot make temporary directory. Fail."
	_exit 1
fi

trap "echo \"Cancled.\";exit 2" 2

f_disk="$tmp_path/disk"

lsblk -p -o KNAME,SIZE,TYPE,VENDOR,MODEL,MOUNTPOINT | tail -n +2 > $f_disk

if [ ! -s "$f_disk" ];
then
	err_message "Cannot found any hard disk drives."
	_exit 0
fi

disk_inf="NO DEVICE SIZE MODEL MOUNTPOINT\n"
row_no="1"

while IFS=" " read -r d_path d_sz d_type d_vendor d_model t_mp;
do
	if [ "$d_type" = "disk" ];
	then
		n_model="$d_vendor""-""$d_model"
		if [ -z "$d_vendor" ] && [ -z "$d_model" ];
		then
			n_model="UNKNOWN"
		fi
		disk_inf="$disk_inf""\n""$row_no $d_path $d_sz $n_model "
		mp=""
		row_no="$(expr $row_no + 1)"
	else
		t_mp="$d_vendor"
		if [ ! -z "$t_mp" ];
		then
			disk_inf="$disk_inf""$t_mp"", "
		fi
	fi
done < $f_disk
echo "$disk_inf" | sed 's/, $//g' | column -t
echo

t_disk=""
while true;
do
	u_no=""
	echo "Select target device no."
	echo "(NOTE : If you want to choice multiple devices, using ',' like '1,2')"
	read -p "Select device (all = a) : " u_no

	case $u_no in
		a)
			u_no="$(seq 1 $row_no)"
		;;
		*)
			u_no="$(echo "$u_no" | tr ',' ' ')"
		;;
	esac

	for s_no in $u_no;
	do
		t_disk="$t_disk""$(echo "$disk_inf" | grep "^$s_no " | awk '{print $2}')"" "
	done

	if [ ! -z "$t_disk" ];
	then
		break
	fi
done

read -p "Input block size (deafult : $bs) : " u_bs
if [ ! -z "$u_bs" ];
then
	bs="$u_bs"
fi

read -p "Input data source path (default: $src) : " u_src
if [ ! -z "$u_src" ];
then
	src="$u_src"
fi

while true;
do
	read -p "Input execution count (default : $cnt) : " u_cnt
	if [ ! -z "$u_cnt" ];
	then
		if [ "$u_cnt" -gt 0 2>/dev/null ];
		then
			cnt="$u_cnt"
			break
		else
			if [ $? -ne 0 ];
			then
				err_message "'$u_cnt' is not number."
			else
				err_message "Count is required lager than 0"
			fi
		fi
	else
		break
	fi
done

echo
echo "[ SUMMARY ]"
echo "Devices : $t_disk"
echo "Block size : $bs"
echo "Data source : $src"
echo "Execution count : $cnt"

echo
read -p "Execute now (y/N) : " u_yn

if [ "$u_yn" != "Y" ] && [ "$u_yn" != "y" ];
then
	err_message "Abort."
	exit 0
fi

for s_cnt in $(seq 1 $cnt);
do
	echo "- Start $s_cnt""th wipe."
	for s_disk in $t_disk;
	do
		echo "---- Start $s_disk"
		sudo dd status=progress if=$src of=$s_disk bs=$bs
		echo "---- End $s_disk"
	done
done

echo "Done."







