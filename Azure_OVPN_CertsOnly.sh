#!/bin/bash
PATHER=$(pwd)
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

# Check dependancies

openvpn --version
if [[ $? != 0 ]];
then
	clear
	echo " OpenVPN Missing... "
   	echo " Standby while we deploy OpenVPN"
	sudo apt update -y && sudo apt upgrade -y
	sudo apt install openvpn -y
fi

curl --version
if [[ $? != 0 ]];
then
	clear
	echo " Curl Missing... "
   	echo " Standby while we deploy curl"
	sudo apt update -y && sudo apt upgrade -y
	sudo apt install curl -y
fi
clear

variable_reset() {
	# This function will reseet the subnet variables to allow for a fresh start
unset dev_client_name
unset dev_server_name
unset vpn_ip
unset server_ip
unset port
unset super_random
unset server_name
unset client_total
unset mtu
unset PROJECT
unset SUBSCRIPTION_NAME
unset REGION
unset REGION2
dns=1.1.1.1
cipher=256
choice=N
}

variable_check() {
	# This function will check for subnet variables that have not yet been set
if [[ -z "${dev_client_name}" ]];
then
	dev_client_name="..."
fi
if [[ -z "${dev_server_name}" ]];
then
	dev_server_name="..."
fi
if [[ -z "${vpn_ip}" ]];
then
	vpn_ip="..."
fi
if [[ -z "${server_ip}" ]];
then
	server_ip="..."
fi
if [[ -z "${port}" ]];
then
	port="..."
fi
if [[ -z "${server_name}" ]];
then
	server_name="..."
fi
if [[ -z "${mtu}" ]];
then
	mtu="..."
fi
if [[ -z "${super_random}" ]];
then
	super_random="..."
fi
}



builder_menu() {
	# This function will create a display for the end user to see what they have done
variable_check
clear
echo
echo " #############################################################################"
echo " #############################################################################"
echo " ###                                                                       ###"
echo " ###        We need the following information for your Subnet Server       ###"
echo " ###                                                                       ###"
echo " #############################################################################"
echo " #############################################################################"
echo " ###                                ##  " 
echo " ###    Examples:                   ##    Your Choices: "  
echo " ###                                ##  "
echo " ###                                ##  Project Name: ${PROJECT}"
echo " ###                                ##  "
echo " ### VPN Public IP: x.x.x.x         ##  VPN Server Name: "${server_name}""
echo " ### VPN Server Name: flounder      ##  VPN Port Number: "${port}""
echo " ### VPN Port Number: 443           ##  VPN Server Subnet: "${server_ip}""
echo " ### VPN Server Subnet: private IP  ##  VPN Server DNS: "${dns}"" 
echo " ### VPN Server Dev Name: mwr       ##  VPN Server Dev Name: "${dev_server_name}""
echo " ###                                ##  VPN Client Dev Name: "${dev_client_name}""
echo " ###                                ##  VPN Encryption Level: "${cipher}""
echo " ###                                ##  VPN Clients: "${client_total}""
echo " ###                                ##  VPN MTU: "${mtu}""
echo " ###                                ##  Super Random Port: "${super_random}""
echo " ###                                ##  "
echo " ###                                ##  "
echo " #############################################################################"
echo " #############################################################################"
echo
}


# Setting the choice variable to "N" will allow it loop on the first iteration
choice=N


builder_variables() {
	# This function will interact with the user to receive inputs
variable_reset
while [[ "${choice}" == N ]];
do
	echo " What is your VPN Server's Name (mwr)?"
	read -p " > " server_name
	if [[ -z "${server_name}" ]];
	then
		server_name=mwr
	fi
 	if [[ -d "./${server_name}_subnet_vpn" ]];
	then
		clear
		echo "New VPN Folder already exists."
		echo "Do you want to overwrite it [y/N]?"
		read -p " > " overwrite
		if [[ "${overwrite}" == [y/Y] ]];
		then
			rm -rf ./"${server_name}"_subnet_vpn
		else
			clear
			echo "You chose not to overwrite the directoy."
			echo "Terminating the script to let you figure it out"
			exit
		fi
	fi
	builder_menu
	echo " What port do you want to use (443)?"
	read -p " > " port
	if [[ -z "${port}" ]];
	then
		port=443
	fi
 	builder_menu
	echo " Would you like to increase survivability by using random ports also (yes or [no])?"
	read -p " > " super_random
 	super_random=$(echo ${super_random} | tr '[:upper:]' '[:lower:]')
	if [[ -z "${super_random}" ]];
	then
		super_random=no
	fi
	builder_menu
	echo " What is your Server's DHCP Subnet for users devices (172.25.0.0)?"
	read -p " > " server_ip
	if [[ -z "${server_ip}" ]];
	then
		server_ip=172.25.0.0
	fi
	builder_menu
	echo " What DNS Server would you like to use (1.1.1.1)?"
	read -p " > " dns
	if [[ -z "${dns}" ]];
	then
		dns=1.1.1.1
	fi
	dev_server_name=vpn
	dev_client_name=tun
	builder_menu
	echo " How many clients do you want (5)?"
	read -p " > " client_total
	if [[ -z "${client_total}" ]];
	then
		client_total=5
	fi
	builder_menu
	echo " What MTU would you like to set your tunnel to (1450)?"
	echo " If you are tunneling through another VPN you may want to drop it"
	echo
	echo " Suggestions:"
	echo
	echo " Direct Internet - 1450"
	echo " Through another VPN - 1350"
	echo " Through multiple tunnels - 1250"
	echo " Lowest I have needed was 1170"
	echo 
	echo " Or you can pick any other number after doing some testing"
	read -p " > " mtu
	if [[ -z "${mtu}" ]];
	then
		mtu=1450
	fi
	builder_menu
	echo " Do these options look correct? [y/N]"
	read -p " > " choice
	if [[ "${choice}" != [y/Y] ]];
	then
		variable_reset
	fi

done
}
builder_variables



VPN_PORT=${port}
clear


subnet_config_builder() {
# This function generates the directives for the OpenvVPN Configurations

tee ./"${server_name}"_server.conf << EOF
# OpenVPN Subnet Server Configuration generated by VPN_Builder.sh
log ${server_name}_server.log
topology subnet
dev-type tun
dev ${dev_server_name}
port ${port}
server ${server_ip} 255.255.255.0
ncp-ciphers AES-${cipher}-GCM:AES-${cipher}-CBC
cipher AES-${cipher}-GCM
auth SHA256
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
verify-x509-name ${server_name}_client name-prefix
remote-cert-tls client
tls-version-min 1.3 or-highest
chroot ${server_name}-jail
user nobody
group nogroup
persist-key
persist-tun
verb 4
mute 20
keepalive 10 60
fast-io
mssfix ${mtu}
dh none
push "block-outside-dns"
push "redirect-gateway def1"
push "dhcp-option DNS ${dns}"
tls-server

# Inline Certs
<ca>
EOF
server="./"${server_name}"_server.conf"


cat ./pki/ca.crt >> "${server}"
echo "</ca>" >> "${server}"
echo "<cert>" >> "${server}"
grep -A 100000 "BEGIN CERTIFICATE" ./pki/issued/"${server_name}"_server.crt >> "${server}"
echo "</cert>" >> "${server}"
echo "<key>" >> "${server}"
grep -A 100000 "BEGIN PRIVATE" ./pki/private/"${server_name}"_server.key >> "${server}"
echo "</key>" >> "${server}"
echo "<tls-crypt>" >> "${server}"
cat ./ta.key >> "${server}"
echo "</tls-crypt>" >> "${server}"

client=1
while [[ "${client}" -le "${client_total}" ]];
do
tee ./"${server_name}"_client_"${client}".ovpn << EOF
# OpenVPN Point-to-Point Client Configuration generated by VPN_Builder.sh
#### These lines are commented to help meet compatibility with some versions of windows ####
#log ${server_name}_client.log
#topology subnet
############################################################################################
dev-type tun
dev ${dev_client_name}
client
EOF

if [[ "${super_random}" == 'yes' ]];
then
tee -a ./"${server_name}"_client_"${client}".ovpn << EOF
remote-random
remote ${vpn_ip} 58231
remote ${vpn_ip} 24184
remote ${vpn_ip} 11032
remote ${vpn_ip} 34882
remote ${vpn_ip} 20132
remote ${vpn_ip} 40321
remote ${vpn_ip} 60241
remote ${vpn_ip} 10402
EOF
fi

tee -a ./"${server_name}"_client_"${client}".ovpn << EOF
remote ${vpn_ip} ${port}
nobind
ncp-ciphers AES-${cipher}-GCM:AES-${cipher}-CBC
cipher AES-${cipher}-GCM
auth SHA256
tls-cipher TLS-ECDHE-RSA-WITH-AES-256-GCM-SHA384
verify-x509-name ${server_name}_server name
remote-cert-tls server
tls-version-min 1.3 or-highest
persist-key
persist-tun
verb 4
mute 20
keepalive 10 60
fast-io
mssfix ${mtu}

# Inline Certs
<ca>
EOF
clear

clientconf="./"${server_name}"_client_"${client}".ovpn"

cat ./pki/ca.crt >> "${clientconf}"
echo "</ca>" >> "${clientconf}"
echo "<cert>" >> "${clientconf}"
grep -A 100000 "BEGIN CERTIFICATE" ./pki/issued/"${server_name}"_client_"${client}".crt >> "${clientconf}"
echo "</cert>" >> "${clientconf}"
echo "<key>" >> "${clientconf}"
grep -A 100000 "BEGIN PRIVATE" ./pki/private/"${server_name}"_client_"${client}".key >> "${clientconf}"
echo "</key>" >> "${clientconf}"
echo "<tls-crypt>" >> "${clientconf}"
cat ./ta.key >> "${clientconf}"
echo "</tls-crypt>" >> "${clientconf}"
((client++))
done
}

subnet_scripted_cert_build() {
# This function needs to be run after the p2p_config_builder function in order to use a folder it created
# This function builds the certs without a CA Password

if [[ -d "./${server_name}_subnet_vpn" ]];
then
	rm -rf ./"${server_name}"_subnet_vpn
fi
mkdir ./"${server_name}"_subnet_vpn/
cp -r ./easy-rsa ./"${server_name}"_subnet_vpn/
cd ./"${server_name}"_subnet_vpn
easyrsa="./easy-rsa/easyrsa3/easyrsa"
bash "${easyrsa}" init-pki
# Increasing the KEY Size from 2048 to 4096
echo "set_var EASY_RSA_KEY_SIZE 4096" >> pki/vars
bash "${easyrsa}" --batch --req-cn="${server_name}_ca" build-ca nopass 
# This is temproary until I can find a better solution to avoid prompts
sed -i 's/read input/input=yes/g' "${easyrsa}"
bash "${easyrsa}" build-server-full "${server_name}_server" nopass
client=1
while [[ "${client}" -le "${client_total}" ]];
do
bash "${easyrsa}" build-client-full "${server_name}_client_"${client}"" nopass
((client++))
done
# This is temporary until I can find a better solution to avoid prompts
sed -i 's/input=yes/read input/g' "${easyrsa}"
openvpn --genkey --secret ta.key
if [[ ${?} != 0 ]];
then
	openvpn --genkey secret ta.key
fi
clear
}


subnet_cert_builder() {
# This function needs to be run after the subnet_config_builder function in order to use a folder it created
if [[ -d "./${server_name}_subnet_vpn" ]];
then
	clear
	echo "New VPN Folder already exists."
	echo "Do you want to overwrite it [y/N]?"
	read -p " > " overwrite
	if [[ "${overwrite}" == [y/Y] ]];
	then
		rm -rf ./"${server_name}"_subnet_vpn
	else
		clear
		echo "You chose not to overwrite the directoy."
		echo "Terminating the script to let you figure it out"
		exit
	fi
fi
mkdir ./"${server_name}"_subnet_vpn/
cp -r ./easy-rsa ./"${server_name}"_subnet_vpn/
cd ./"${server_name}"_subnet_vpn
easyrsa="./easy-rsa/easyrsa3/easyrsa"
bash "${easyrsa}" init-pki
# Increasing the KEY Size from 2048 to 4096
echo "set_var EASY_RSA_KEY_SIZE 4096" >> pki/vars
bash "${easyrsa}" --batch --req-cn="${server_name}_ca" build-ca nopass 
# This is temproary until I can find a better solution to avoid prompts
sed -i 's/read input/input=yes/g' "${easyrsa}"
bash "${easyrsa}" build-server-full "${server_name}_server" nopass
client=1
while [[ "${client}" -le "${client_total}" ]];
do
bash "${easyrsa}" build-client-full "${server_name}_client_"${client}"" nopass
((client++))
done
# This is temporary until I can find a better solution to avoid prompts
sed -i 's/input=yes/read input/g' "${easyrsa}"
openvpn --genkey --secret ta.key
if [[ ${?} != 0 ]];
then
	openvpn --genkey secret ta.key
fi
clear
echo 
}

clear

subnet_cert_builder
subnet_config_builder
subnet_script_builder
echo
cd ..



cd "${server_name}"_subnet_vpn
rm -rf ta.key
mkdir server_files
mv *.sh ./server_files/
mv *.conf ./server_files/
mkdir server_files/client_certs
mv *.ovpn ./server_files/client_certs/
cd server_files


cd client_certs






cd server_files/client_certs

clear
cd ../../
cd server_files/client_certs


xdg-open .
