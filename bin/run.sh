#########################################################################
# File Name: run.sh
# Author: HouJP
# mail: houjp1992@gmail.com
# Created Time: Thu 10 Dec 2015 08:57:41 PM CST
#########################################################################
#! /bin/bash

PATH_PRE="`pwd`"
PATH_NOW="`dirname $0`"
cd ${PATH_NOW}
# source config
cd ${PATH_PRE}

#set -o pipefail
#set -x

g_local_host=
g_hosts=
g_users=
g_ford=
g_path=

function run_cmd() {
	local ret=

	for ((hid = 0; hid < ${#g_hosts[@]}; ++hid))
	do
		des="${g_users[$hid]}@${g_hosts[$hid]}"
		echo "[INFO] run cmd.sh on ${des} ..."
		scp cmd.sh ${des}:/tmp/
		if [ 0 -ne $? ]; then
			echo "[ERROR] send cmd.sh to $des meet error!"
			return 255
		fi
		ssh $des "sh /tmp/cmd.sh"
		if [ 0 -ne $? ]; then
			echo "[ERROR] run cmd.sh on $des meet error!"
		fi
		ssh $des "rm -rf /tmp/cmd.sh"
		echo "[INFO] run cmd.sh on ${des} done."
	done
}

function send_files() {
	local hn=${#g_hosts[@]}
	local fn=${#g_ford[@]}
	local des=
	for ((hid = 0; hid < hn; ++hid))
	do
		if [ x"$g_local_host" == x"${g_hosts[$hid]}" ]; then
			continue
		fi

		des="${g_users[$hid]}@${g_hosts[$hid]}"

		for ((fid = 0; fid < fn; ++fid))
		do
			echo "[INFO] send file/directory ${g_path[$fid]}/${g_ford[$fid]} to $des ..."
			ssh ${des} "mkdir -p ${g_path[$fid]}"
			if [ 0 -ne $? ]; then
				echo "[ERROR] make full path ${g_path[$fid]} on $des meet error!"
				return 255
			fi
			scp -r ${g_path[$fid]}/${g_ford[$fid]} ${des}:${g_path[$fid]}/
			if [ 0 -ne $? ]; then
				echo "[ERROR] send file/directory ${g_path[$fid]}/${g_ford[$fid]} to $des meet error!"
				return 255
			fi
			echo "[INFO] send file/directory ${g_path[$fid]}/${g_ford[$fid]} to $des done."
		done
	done
}

function load_files() {
	eval $(awk 'BEGIN{
		id = 0;
	}{
		if ($0 ~ /^#/) {
			next;
		}
		if (NF != 2) {
			next;
		}
		ford[id] = $1;
		path[id] = $2;
		id += 1;
	}END{
		for (i = 0; i < id; ++i) {
			print "g_ford["i"]="ford[i];
			print "g_path["i"]="path[i];
		}
	}' ../conf/files)
}

function load_hosts() {
	eval $(awk 'BEGIN{
		id = 0;
	}{
		if ($0 ~ /^#/) {
			next;
		}
		if (NF != 2) {
			next;
		}
		hosts[id] = $1;
		users[id] = $2;
		id += 1;
	}END{
		for (i = 0; i < id; ++i) {
			print "g_hosts["i"]="hosts[i];
			print "g_users["i"]="users[i];
		}
	}' ../conf/hosts)
}

function run() {
	if [ 1 -ne $# ]; then
		echo "[ERROR] USAGE: run <local_host>"
		return 1
	fi

	# get local host
	g_local_host=${1}

	# load hosts
	load_hosts
	echo "[INFO] load file conf/hosts done."

	# load files
	load_files
	echo "[INFO] load file conf/files done."

	# send files
	send_files
	if [ 0 -ne $? ]; then
		echo "[ERROR] send files meet error!"
		return 255
	else
		echo "[INFO] send files done."
	fi

	# run cmd
	run_cmd
	if [ 0 -ne $? ]; then
		echo "[ERROR] run cmd meet error!"
		return 255
	else
		echo "[INFO] run cmd all done."
	fi
}

run ${1}
