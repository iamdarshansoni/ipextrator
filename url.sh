#!/bin/bash

function check_url(){

	url=${1}
	echo "$url";
	urlCommand=`curl -s --head --request GET "$url"`

	if (echo "$urlCommand" | grep -Eo '(HTTP/1.1|HTTP/2) 200') > /dev/null; then 
		echo $1" is UP... Processing..."
		extract_hosts $1
		list_end_points $1
	elif (echo "$urlCommand" | grep -Eo '(HTTP/1.1|HTTP/2) 301') > /dev/null; then
		redirect "$urlCommand"
	elif (echo "$urlCommand" | grep -Eo '(HTTP/1.1|HTTP/2) 302') > /dev/null; then
		redirect "$urlCommand"
	else
		echo "host seems down"
	fi
}

function redirect(){
		redirection=`echo "$1" | grep -i 'Location' | awk -F' ' '{print $2}' | awk -F? '{print $1}'`
		#echo "Found Redirection to: "$redirection 
		cutStr=`echo -n $redirection | tail -c 2`; 
		cutStr=`echo -n $cutStr | head -c 1`;

		if [ "$cutStr" == "/" ]; then
			redirection=`echo "$redirection" | rev | cut -c 2- | rev`
		fi
		check_url "$redirection"
: '
		echo "Do you wish to continue? (y/n)"
		read ans
		if [ "$ans" == "y" ]; then
			check_url "$redirection"
		else
			echo "Exiting..."
		fi
'
}

function extract_hosts(){
	
	hosts=`curl -s --request GET $1 | grep -Eo '(http|https)://[^/"]+' | awk -F/ '{print $3}' | awk -F? '{print $1}' | sort -u`

	arr=( $hosts )
	len=${#arr[@]}

	for (( x=0; x<len; x++ ))
	do
		 get_ip_addr $x ${arr[$x]}
		echo "Found an IP: "${ip_arr[$x]}
	done
	
	uniq=($(printf "%s\n" "${ip_arr[@]}" | sort -u)) 
	printf "\nUnique IP Addresses:\n"
	printf '%s\n' "${uniq[@]}"
}

function list_end_points(){

	hosts=`curl -s --request GET $1 | grep -Eo '(http|https)://[^$"]+' | sort -u`
	
	echo "$filename"
	arr=( $hosts )

	printf "\nUnique Endpoints\n"
	printf '%s\n' "${hosts[@]}"
	
}

function get_ip_addr(){

	ip=`host $2 | awk '/has address/ { print $4 }'`
	ip_arr[$1]=$ip
}

ip_arr=()
check_url $1


