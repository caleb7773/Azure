#!/bin/bash
project_code=${RANDOM}
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[0m' # No Color
# Connect to Azure CLI
az account show
if ! [[ ${?} == 0 ]];
then
	az login
fi

# Modify some files we will use later to test when the multithreading is complete
# We will delete these later in the script
echo n > ${project_code}-vm1
echo n > ${project_code}-vm2
echo n > ${project_code}-first_finished
echo n > ${project_code}-second_finished







variable_reset() {
	# This function will reseet the subnet variables to allow for a fresh start
unset dev_client_name
unset dev_server_name
unset vpn_ip
unset server_ip
unset port
unset server_name
unset client_total
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
echo " ###                                ##  Front End Region: ${REGION}"
echo " ###                                ##  Egress Region: ${REGION2}"
echo " ###                                ##  "
echo " ### VPN Public IP: x.x.x.x         ##  VPN Server Name: "${server_name}""
echo " ### VPN Server Name: flounder      ##  VPN Port Number: "${port}""
echo " ### VPN Port Number: 443           ##  VPN Server Subnet: "${server_ip}""
echo " ### VPN Server Subnet: private IP  ##  VPN Server DNS: "${dns}"" 
echo " ### VPN Server Dev Name: mwr       ##  VPN Server Dev Name: "${dev_server_name}""
echo " ###                                ##  VPN Client Dev Name: "${dev_client_name}""
echo " ###                                ##  VPN Encryption Level: "${cipher}""
echo " ###                                ##  VPN Clients: "${client_total}""
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
	clear
 	# Reach out to Azure and grab the subscriptions this user has access to.
  	echo  -e " What subscription do you want to deploy in ${GREEN}(s2vaus-sandbox-tactical)${NC}?"
  	echo  -e " If you press ${RED}ENTER${NC} you will pick the default value."
   	echo  -e " ${GREEN}Pick the number${NC} corresponding to your choice"
   	echo
	num=1
	az account list | grep s2vaus | cut -d '"' -f4 | sort > ${project_code}-subs.list
	
	for i in $(cat ${project_code}-subs.list);
	do 
		echo " (${num}) ${i}"
		((num++))
	done > ${project_code}-output.list
	rm -rf ${project_code}-subs.list
	echo -e "${GREEN}"
	cat ${project_code}-output.list
	echo -e "${NC}"
    	echo
	read -N 1 -p " Number is -> " SUBSCRIPTION_NAME
 	SUBSCRIPTION_NAME=$(cat ${project_code}-output.list | head -${SUBSCRIPTION_NAME} | tail -1 | cut -d ' ' -f3)
 	rm -rf ${project_code}-output.list
	if [[ -z "${SUBSCRIPTION_NAME}" ]];
	then
		SUBSCRIPTION_NAME=s2vaus-sandbox-tactical
	fi
	SUBSCRIPTION=$(az account list | grep "\"${SUBSCRIPTION_NAME}\"" -B 3 | grep id | cut -d '"' -f4)
	echo
	

	
	# Connect to Azure Subscription
	az account set -s ${SUBSCRIPTION}
	clear
	echo -e " ${RED}Azure Regions:${NC}"

echo "		North America"
echo -e "${GREEN} westus - westus2 - westus3${NC}"
echo -e "${GREEN} westcentralus - northcentralus - southcentralus - centralus${NC}"
echo -e "${GREEN} eastus - eastus2${NC}"
echo -e "${GREEN} canadacentral - canadaeast${NC}"

echo "		Europe"
echo -e "${GREEN} northeurope - westeurope - francecentral${NC}"
echo -e "${GREEN} ukwest - uksouth - switzerlandnorth - germanywestcentral${NC}"
echo -e "${GREEN} norwayeast - swedencentral - polandcentral - italynorth${NC}"

echo "		Asia"
echo -e "${GREEN} eastasia - southeastasia${NC}"
echo -e "${GREEN} centralindia - southindia - westindia${NC}"
echo -e "${GREEN} japaneast - japanwest${NC}"
echo -e "${GREEN} koreacentral - koreasouth${NC}"

echo "		South America"
echo -e "${GREEN} brazilsouth${NC}"
	
echo "		Australia"
echo -e "${GREEN} australiaeast - australiasoutheast - australiacentral${NC}"

echo "		Middle East"
echo -e "${GREEN} uaenorth - qatarcentral${NC}"

echo "		Africa"
echo -e "${GREEN} southafricanorth${NC}"
echo
echo "#############################################################################"
echo "#############################################################################"

	echo	
	echo
	echo
	echo -e " Where do you want your users to ${GREEN}enter${NC} the redirector ${RED}(eastus)${NC}?"
	read -p " > " REGION
	if [[ -z "${REGION}" ]];
	then
		REGION=eastus
	fi
 	echo
 	echo "Validating Region Choice..."
	output=$(az account list-locations -o table)
	if [[ "${output}" != *${REGION}* ]];
	then
		clear
	 	echo -e "${RED} ${REGION} - doesn't exists!${NC}"
	  	echo -e "Please pick a ${GREEN}region from the list${NC}"
	   	echo
		read -p "Press ENTER to try again" ENTER
	     	builder_variables
	fi
  	echo
 	echo "Grabbing Resource Groups in your region..."
  	echo
	az group list | grep "\"${SUBSCRIPTION_NAME}-${REGION}-" | cut -d '"' -f4 | sort > ${project_code}-groups.list
	clear
	if [[ $(cat ${project_code}-groups.list | wc -l) -eq 0 ]];
	then
		echo
	else
		echo
		echo -e " The following Resource Groups are ${RED}already in this region${NC}"
		echo 
		echo -e "${GREEN}"
		cat ${project_code}-groups.list
		echo -e "${NC}"
		echo
		echo -e " ${RED}Do not overlap with any previous Resource Groups${NC}"
		echo
		echo
		echo
	fi
	rm -rf ${project_code}-groups.list
	echo -e " What would you like to name your Project ${GREEN}(twister)${NC}?"
	echo -e " ${GREEN}twister${NC} would be -> ${SUBSCRIPTION_NAME}-${REGION}-${GREEN}twister${NC}-rg"

	read -p " > " PROJECT
	if [[ -z "${PROJECT}" ]];
	then
		PROJECT=twister
	fi
	RESOURCE_GROUP=${SUBSCRIPTION_NAME}-${REGION}-${PROJECT}-rg
   	echo
 	echo "Validating Resource Group Choice..."
	output=$(az group show --name ${RESOURCE_GROUP} 2> /dev/null)
	if [[ "${output}" == *Succeeded* ]];
	then
		clear
	 	echo -e "${RED}Resource Group Already Exists!${NC}"
	  	echo -e "Please pick a ${GREEN}different project name or region${NC}"
	   	echo
		read -p "Press ENTER to try again" ENTER
	     	builder_variables
	fi
	builder_menu
	clear
	echo -e " ${RED}Azure Regions:${NC}"

echo "		North America"
echo -e "${GREEN} westus - westus2 - westus3${NC}"
echo -e "${GREEN} westcentralus - northcentralus - southcentralus - centralus${NC}"
echo -e "${GREEN} eastus - eastus2${NC}"
echo -e "${GREEN} canadacentral - canadaeast${NC}"

echo "		Europe"
echo -e "${GREEN} northeurope - westeurope - francecentral${NC}"
echo -e "${GREEN} ukwest - uksouth - switzerlandnorth - germanywestcentral${NC}"
echo -e "${GREEN} norwayeast - swedencentral - polandcentral - italynorth${NC}"

echo "		Asia"
echo -e "${GREEN} eastasia - southeastasia${NC}"
echo -e "${GREEN} centralindia - southindia - westindia${NC}"
echo -e "${GREEN} japaneast - japanwest${NC}"
echo -e "${GREEN} koreacentral - koreasouth${NC}"

echo "		South America"
echo -e "${GREEN} brazilsouth${NC}"
	
echo "		Australia"
echo -e "${GREEN} australiaeast - australiasoutheast - australiacentral${NC}"

echo "		Middle East"
echo -e "${GREEN} uaenorth - qatarcentral${NC}"

echo "		Africa"
echo -e "${GREEN} southafricanorth${NC}"
echo
echo "#############################################################################"
echo "#############################################################################"

	echo
	echo -e " What region do you want to ${RED}pop out${NC} of ${GREEN}(centralus)${NC}?"
	read -p " > " REGION2
	if [[ -z "${REGION2}" ]];
	then		
		REGION2=centralus
	fi
    	echo
 	echo "Validating Region Choice..."
	output=$(az account list-locations -o table)
	if [[ "${output}" != *${REGION2}* ]];
	then
		clear
	 	echo -e "${RED} ${REGION2} - doesn't exists!${NC}"
	  	echo -e "Please pick a ${GREEN}region from the list${NC}"
	   	echo
		read -p "Press ENTER to try again" ENTER
	     	builder_variables
	fi
	builder_menu

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
	echo " Do these options look correct? [y/N]"
	read -p " > " choice
	if [[ "${choice}" != [y/Y] ]];
	then
		variable_reset
	fi

done
}
builder_variables


RESOURCE_GROUP=${SUBSCRIPTION_NAME}-${REGION}-${PROJECT}-rg
VNET1=${SUBSCRIPTION_NAME}-${REGION}-FE-vnet
VNET2=${SUBSCRIPTION_NAME}-${REGION2}-BE-vnet
V_SUBNET1_NAME=FE-sub
V_SUBNET1=10.0.101.0/24
V_SUBNET2_NAME=BE-sub
V_SUBNET2=10.1.102.0/24
NSG1=${SUBSCRIPTION_NAME}-${REGION}-FE-nsg
NSG2=${SUBSCRIPTION_NAME}-${REGION2}-BE-nsg
VNIC1=${SUBSCRIPTION_NAME}-${REGION}-FE-vnic
VNIC2=${SUBSCRIPTION_NAME}-${REGION2}-BE-vnic
VNIC1_IP=${SUBSCRIPTION_NAME}-${REGION}-FE-ip
VNIC2_IP=${SUBSCRIPTION_NAME}-${REGION2}-BE-ip
VMNAME=VPN_FE
VMNAME2=VPN_BE
VPN_PORT=${port}
clear
# Create a new Resource Group
echo -e "${NC}Creation has begun on - ${RESOURCE_GROUP}${RED}"
echo -e "${RED}"
az group create \
    --name ${RESOURCE_GROUP} \
    --location ${REGION} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${RESOURCE_GROUP}${NC}"

first_instance() {
echo -e "${NC}Creation has begun on - ${VNET1}${RED}"
echo -e "${RED}"
az network vnet create \
    --name ${VNET1} \
    --resource-group ${RESOURCE_GROUP} \
    --address-prefix 10.0.0.0/16 \
    --subnet-name ${V_SUBNET1_NAME} \
    --location ${REGION} \
    --subnet-prefixes ${V_SUBNET1} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNET1}${NC}"

echo -e "${NC}Creation has begun on - ${NSG1}${RED}"
echo -e "${RED}"
az network nsg create \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --name ${NSG1} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${NSG1}${NC}"

echo -e "${NC}Modification has initiated on - ${NSG1}${RED}"
echo -e "${RED}"
az network nsg rule create \
    --resource-group ${RESOURCE_GROUP} \
    --nsg-name ${NSG1} \
    --name SSH-rule \
    --priority 300 \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --protocol Tcp \
    --description "Allow SSH" > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished modifying for SSH- ${NSG1}${NC}"

echo -e "${NC}Modification has initiated on - ${NSG1}${RED}"
echo -e "${RED}"
az network nsg rule create \
    --resource-group ${RESOURCE_GROUP} \
    --nsg-name ${NSG1} \
    --name VPN-rule \
    --priority 310 \
    --destination-address-prefixes '*' \
    --destination-port-ranges ${VPN_PORT} \
    --protocol Udp \
    --description "Allow VPN" > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished modifying for redirector- ${NSG1}${NC}"
      
echo -e "${NC}Creation has begun on - ${VNIC1_IP}${RED}"
echo -e "${RED}"
az network public-ip create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC1_IP} \
    --sku Standard \
    --location ${REGION} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC1_IP}${NC}"

echo -e "${NC}Creation has begun on - ${VNIC1}${RED}"
echo -e "${RED}"
az network nic create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC1} \
    --vnet-name ${VNET1} \
    --location ${REGION} \
    --subnet ${V_SUBNET1_NAME} \
    --network-security-group ${NSG1} \
    --public-ip-address ${VNIC1_IP} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC1}${NC}"
}


second_instance() {
echo -e "${NC}Creation has begun on - ${VNET2}${RED}"
echo -e "${RED}"
az network vnet create \
    --name ${VNET2} \
    --resource-group ${RESOURCE_GROUP} \
    --address-prefix 10.1.0.0/16 \
    --subnet-name ${V_SUBNET2_NAME} \
    --location ${REGION2} \
    --subnet-prefixes ${V_SUBNET2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNET2}${NC}"
    
echo -e "${NC}Creation has begun on - ${NSG2}${RED}"
echo -e "${RED}"
az network nsg create \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION2} \
    --name ${NSG2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${NSG2}${NC}"

echo -e "${NC}Creation has begun on - ${VNIC2_IP}${RED}"
echo -e "${RED}"
az network public-ip create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC2_IP} \
    --sku Standard \
    --location ${REGION2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC2_IP}${NC}"

echo -e "${NC}Creation has begun on - ${VNIC2}${RED}"
echo -e "${RED}"
az network nic create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC2} \
    --vnet-name ${VNET2} \
    --location ${REGION2} \
    --subnet ${V_SUBNET2_NAME} \
    --network-security-group ${NSG2} \
    --public-ip-address ${VNIC2_IP}  > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC2}${NC}"

 
}

# This is some fancy multithreading
# First it will run the first function and then the second function without waiting
first_instance && echo y > ${project_code}-first_finished & second_instance && echo y > ${project_code}-second_finished

while [[ $(cat ${project_code}-first_finished) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-second_finished) != 'y' ]];
do
	sleep 1s
done

vNet1Id=$(az network vnet show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${VNET1} \
  --query id --out tsv)
  
vNet2Id=$(az network vnet show \
  --resource-group ${RESOURCE_GROUP} \
  --name ${VNET2} \
  --query id \
  --out tsv)
echo -e "${NC}Peering has begun between - ${VNET1} and ${VNET2}${RED}"
echo -e "${RED}"
az network vnet peering create \
  --name Peer_to_BE \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET1} \
  --remote-vnet $vNet2Id \
  --allow-vnet-access > /dev/null
echo -e "${NC}"
  
az network vnet peering create \
  --name Peer_to_FE \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET2} \
  --remote-vnet $vNet1Id \
  --allow-vnet-access > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished Peering - ${VNET1} and ${VNET2}${NC}"
 
build_one() {
    
# Create VM
echo -e "${NC}Creation has begun on - ${VMNAME}${RED}"
echo -e "${RED}"
az vm create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VMNAME} \
    --location ${REGION} \
    --image "Ubuntu2204" \
    --size Standard_DS3_v2 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC1} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VMNAME}${NC}"
}
   build_two() {
echo -e "${NC}Creation has begun on - ${VMNAME2}${RED}"
echo -e "${RED}"
az vm create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VMNAME2} \
    --location ${REGION2} \
    --image "Ubuntu2204" \
    --size Standard_DS3_v2 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VMNAME2}${NC}"
} 
   
build_one && echo y > ${project_code}-vm1 & build_two && echo y > ${project_code}-vm2

while [[ $(cat ${project_code}-vm1) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-vm2) != 'y' ]];
do
	sleep 1s
done
    
rm -rf ${project_code}-first_finished
rm -rf ${project_code}-second_finished
rm -rf ${project_code}-vm1
rm -rf ${project_code}-vm2

    
# Grabbing IP Addresses
export VM_1_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query privateIps --output tsv)
export VM_2_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query privateIps --output tsv)
export VM_1_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query publicIps --output tsv)
export VM_2_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query publicIps --output tsv)

vpn_ip=${VM_1_Public_IP_ADDRESS}

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
remote ${vpn_ip}
port ${port}
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
clear
echo 
}
subnet_script_builder() {

tee fe_deployment_script.sh << EOF
#!/bin/bash
#
# Execute on both ends of the Subnet tunnel
# This script will setup the Jail
sudo apt update && sudo apt upgrade -y

# Adding IPTables Persistent Options
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections
sudo apt install iptables-persistent -y

hostname=\$(cat /etc/hostname)
sudo sed -i "s/localhost/\${hostname}/g" /etc/hosts

# Modify the IPTables Rules Page
sudo tee -a /etc/iptables/rules.v4 << EOFFF
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -s 0.0.0.0/0 -p tcp --dport 22 -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p udp --dport ${port} -m conntrack --ctstate NEW -j DNAT --to-destination ${VM_2_Private_IP_ADDRESS}
-A POSTROUTING -p udp --dport ${port} -m conntrack --ctstate NEW -j SNAT --to-source ${VM_1_Private_IP_ADDRESS}
COMMIT
EOFFF

sudo iptables-restore /etc/iptables/rules.v4

# Enabling IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
exit
EOF

tee be_deployment_script.sh << EOF
#!/bin/bash
#
# Execute on both ends of the Subnet tunnel
# This script will setup the Jail
sudo apt update && sudo apt upgrade -y
sudo apt install openvpn openvpn-systemd-resolved -y

# Adding IPTables Persistent Options
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean false | sudo debconf-set-selections
sudo apt install iptables-persistent -y

hostname=\$(cat /etc/hostname)
sudo sed -i "s/localhost/\${hostname}/g" /etc/hosts

# Modify the IPTables Rules Page
sudo tee -a /etc/iptables/rules.v4 << EOFFF
*filter
:INPUT DROP [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m conntrack --ctstate INVALID -j DROP
-A INPUT -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A INPUT -s ${VM_1_Private_IP_ADDRESS}/32 -p udp --dport ${port} -j ACCEPT
-A INPUT -s ${VM_1_Private_IP_ADDRESS}/32 -p tcp --dport 22 -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -s ${server_ip}/24 -o eth0 -j MASQUERADE
COMMIT
*filter
EOFFF

sudo iptables-restore /etc/iptables/rules.v4

# Setting up Jail Directory
sudo mkdir -p /etc/openvpn/${server_name}-jail/tmp
sudo chmod 1777 /etc/openvpn/${server_name}-jail/tmp

# Enabling IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

sudo mv /tmp/${server_name}_server.conf /etc/openvpn/

# Start up the VPN
sudo systemctl start openvpn@${server_name}_server
sudo systemctl enable openvpn@${server_name}_server
exit
EOF
clear
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


ssh-keyscan -H ${VM_1_Public_IP_ADDRESS} >> ~/.ssh/known_hosts




scp -o StrictHostKeyChecking=no fe_deployment_script.sh azureuser@${VM_1_Public_IP_ADDRESS}:/tmp/
scp -o StrictHostKeyChecking=no -J azureuser@${VM_1_Public_IP_ADDRESS} be_deployment_script.sh ${server_name}_server.conf azureuser@${VM_2_Private_IP_ADDRESS}:/tmp/
cd client_certs

clear
echo
ssh -o StrictHostKeyChecking=no azureuser@${VM_1_Public_IP_ADDRESS} 'sudo bash /tmp/fe_deployment_script.sh && logout'
clear
echo
ssh -o StrictHostKeyChecking=no -J azureuser@${VM_1_Public_IP_ADDRESS} azureuser@${VM_2_Private_IP_ADDRESS} 'sudo bash /tmp/be_deployment_script.sh && logout'

clear
cd ../../
cd server_files/client_certs


xdg-open .
