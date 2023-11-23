#!/bin/bash
project_code=${RANDOM}
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color



# Kill the script if someone runs it as root

if [[ $(id -u) == 0 ]];
then
	echo
	echo "Do not run this as root you joker!"
	exit 1
fi

clear
echo
echo -e "${GREEN}
