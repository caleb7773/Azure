#!/bin/bash
PATHER=$(pwd)
trap ctrl_c INT
function ctrl_c() {
	rm -rf ${PATHER}/${project_code}*
 	exit
}
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
	echo " OpenVPN Missing... "
	sudo apt update -y
	sudo apt install openvpn -y
fi

git --version
if [[ $? != 0 ]];
then
	echo " Git Missing... "
	sudo apt update -y
	sudo apt install git -y
fi

curl --version
if [[ $? != 0 ]];
then
	echo " Curl Missing... "
	sudo apt update -y
	sudo apt install curl -y
fi

az --version
if [[ $? != 0 ]];
then
	echo " AZ CLI Missing... "
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
fi

# Generate SSH Key if it does not exist

if [[ -f ~/.ssh/id_rsa ]]; 
then 
	echo "SSH Keyfile exists"
else 
	echo "SSH Keyfile does not exist"
	ssh-keygen -N "" -o -f ~/.ssh/id_rsa
fi






# Connect to Azure CLI
az account show
if ! [[ ${?} == 0 ]];
then
	az login
fi



builder_menu() {
# This function will create a display for the end user to see what they have done
clear
echo
echo " #############################################################################"
echo " #############################################################################"
echo " ###                                                                       ###"
echo -e " ###        ${GREEN}We need the following information for your Redirector Pair${NC}     ###"
echo " ###                                                                       ###"
echo " #############################################################################"
echo " #############################################################################"
echo " ###  " 
echo -e " ###    ${GREEN}Your Choices:${NC} "  
echo " ###  "
echo -e " ###  ${GREEN}Subscription Name:${RED} ${SUBSCRIPTION_NAME}${NC}"
echo -e " ###  ${GREEN}Project Name:${RED} ${PROJECT}${NC}"
echo " ###  "
echo -e " ###  ${GREEN}Front End Region:${RED} ${REGION}${NC}"
echo -e " ###  ${GREEN}Egress Region:${RED} ${REGION2}${NC}"
echo " ###  "
echo -e " ###  ${GREEN}Endpoint IP:${RED} ${ENDPOINT}${NC}"
echo -e " ###  ${GREEN}Endpoint Port:${RED} ${ENDPORT}${NC}"
echo -e " ###  ${GREEN}Endpoint Port:${RED} ${PROTOCOL}${NC}"
echo " ###"
echo " #############################################################################"
echo " #############################################################################"
echo
}

# Setting the choice variable to "N" will allow it loop on the first iteration
choice=N

builder_variables() {
# This function will interact with the user to receive inputs
while [[ "${choice}" != [y/Y] ]];
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
	region_skus=$(az vm list-sizes --location "${REGION}" -o table)
 	if [[ ${region_skus} != *Standard_B1s* ]]; 
 	then 
		clear
	 	echo -e "${RED} ${REGION} - doesn't support the VM SKU type!${NC}"
	  	echo -e "Please pick a ${GREEN}different region from the list${NC}"
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
	RESOURCE_GROUP=${SUBSCRIPTION_NAME}-${REGION}-${PROJECT}-TP-rg
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
	region_skus=$(az vm list-sizes --location "${REGION2}" -o table)
 	if [[ ${region_skus} != *Standard_B1s* ]]; 
 	then 
		clear
	 	echo -e "${RED} ${REGION2} - doesn't support the VM SKU type!${NC}"
	  	echo -e "Please pick a ${GREEN}different region from the list${NC}"
	   	echo
		read -p "Press ENTER to try again" ENTER
	     	builder_variables
 	fi
	builder_menu
	echo
	echo -e " Your endpoint is the service you are trying ${GREEN}to reach out to${NC}"
	echo -e "  The service you are trying to ${GREEN}hide attribution to${NC} by using this redirector"
	echo
	echo -e " What is your endpoint/service ${GREEN}IP${NC} i.e. ${GREEN}23.62.11.8${NC}?"
	read -p " > " ENDPOINT
	builder_menu
	echo
	echo -e " What ${GREEN}Port${NC} is your endpoint using i.e. ${GREEN}443${NC}?"
	read -p " > " ENDPORT
		if [[ -z "${ENDPORT}" ]];
	then
		ENDPORT=443
	fi
	builder_menu
	echo
	echo -e " What ${GREEN}Protocol${NC} is running your service?"
    	echo -e " ${GREEN}Pick the number${NC} corresponding to your choice"
	echo -e ${GREEN}
	echo " (1) TCP"
	echo " (2) UDP"
	echo -e ${NC}
	read -N 1 -p " Number is -> " PROTOCOL
	if [[ ${PROTOCOL} == 1 ]];
	then
		PROTOCOL=TCP
	else
		PROTOCOL=UDP
	fi
	builder_menu
	echo -e " Do these options look correct? ${GREEN}[Y${NC}/${RED}N]${NC}"
	read -p " > " choice
done
}
builder_variables
clear
VNET1=${SUBSCRIPTION_NAME}-${REGION}-FE-vnet
VNET2=${SUBSCRIPTION_NAME}-${REGION2}-BE-vnet
VNET3=${SUBSCRIPTION_NAME}-${REGION2}-Bastion-vnet
V_SUBNET1_NAME=FE-sub
V_SUBNET1=10.0.101.0/24
V_SUBNET2_NAME=BE-sub
V_SUBNET2=10.1.102.0/24
NSG1=${SUBSCRIPTION_NAME}-${REGION}-FE-nsg
NSG2=${SUBSCRIPTION_NAME}-${REGION2}-BE-nsg
NSG3=${SUBSCRIPTION_NAME}-${REGION2}-Bastion-nsg
VNIC1=${SUBSCRIPTION_NAME}-${REGION}-FE-vnic
VNIC2=${SUBSCRIPTION_NAME}-${REGION2}-BE-vnic
VNIC3=${SUBSCRIPTION_NAME}-${REGION2}-Bastion-vnic
VNIC1_IP=${SUBSCRIPTION_NAME}-${REGION}-FE-ip
VNIC2_IP=${SUBSCRIPTION_NAME}-${REGION2}-BE-ip
VNIC3_IP=${SUBSCRIPTION_NAME}-${REGION2}-Bastion-ip
VMNAME=REDIR_FE
VMNAME2=REDIR_BE

# Create a new Resource Group
echo -e "${NC}Creation has begun on - ${RESOURCE_GROUP}${RED}"
echo -e "${RED}"
az group create \
    --name ${RESOURCE_GROUP} \
    --location ${REGION} > /dev/null
username=$(az account show | grep onmicrosoft | cut -d '@' -f1 | cut -d '"' -f4)
grouppy=$(az group show -n ${RESOURCE_GROUP} --query id --output tsv)
az tag create --resource-id $grouppy --tags UserAzure=${username} Persistent=unknown UseCase=unknown Scripted=TechAzurePanda > /dev/null
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
    --name VPN-rule \
    --priority 310 \
    --destination-address-prefixes '*' \
    --destination-port-ranges ${ENDPORT} \
    --protocol ${PROTOCOL} \
    --description "Allow Redirector Traffic" > /dev/null
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
third_instance() {
    
echo -e "${NC}Creation has begun on - ${NSG3}${RED}"
echo -e "${RED}"
az network nsg create \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION2} \
    --name ${NSG3} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${NSG3}${NC}"

echo -e "${NC}Creation has begun on - ${VNIC3_IP}${RED}"
echo -e "${RED}"
az network public-ip create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC3_IP} \
    --sku Standard \
    --location ${REGION2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC3_IP}${NC}"

echo -e "${NC}Creation has begun on - ${VNIC3}${RED}"
echo -e "${RED}"
az network nic create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC3} \
    --vnet-name ${VNET2} \
    --location ${REGION2} \
    --subnet ${V_SUBNET2_NAME} \
    --network-security-group ${NSG3} \
    --public-ip-address ${VNIC3_IP}  > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VNIC3}${NC}"

echo -e "${NC}Modification has initiated on - ${NSG3}${RED}"
echo -e "${RED}"
az network nsg rule create \
    --resource-group ${RESOURCE_GROUP} \
    --nsg-name ${NSG3} \
    --name SSH-rule \
    --priority 300 \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --protocol Tcp \
    --description "Allow SSH" > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished modifying for SSH - ${NSG3}${NC}"
}


# Modify some files we will use later to test when the multithreading is complete
# We will delete these later in the script


echo n > ${project_code}-first_finished
echo n > ${project_code}-second_finished
echo n > ${project_code}-third_finished

# This is some fancy multithreading
# First it will run the first function and then the second function without waiting
first_instance && echo y > ${project_code}-first_finished & second_instance && echo y > ${project_code}-second_finished & third_instance && echo y > ${project_code}-third_finished

while [[ $(cat ${project_code}-first_finished) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-second_finished) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-third_finished) != 'y' ]];
do
	sleep 1s
done

rm -rf ${project_code}-first_finished
rm -rf ${project_code}-second_finished
rm -rf ${project_code}-third_finished

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
    --size Standard_B1s \
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
    --size Standard_B1s \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC2} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - ${VMNAME2}${NC}"
} 
build_three() { 
 # Building the Bastion Host
echo -e "${NC}Creation has begun on - Bastion${RED}"
echo -e "${RED}"
az vm create \
    --resource-group ${RESOURCE_GROUP} \
    --name Bastion \
    --location ${REGION2} \
    --image "Ubuntu2204" \
    --size Standard_B1s \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC3} > /dev/null
echo -e "${NC}"
echo -e "${GREEN}Finished - Bastion${NC}"
 }
 
echo n > ${project_code}-vm1
echo n > ${project_code}-vm2
echo n > ${project_code}-vm3

build_one && echo y > ${project_code}-vm1 & build_two && echo y > ${project_code}-vm2 & build_three && echo y > ${project_code}-vm3

while [[ $(cat ${project_code}-vm1) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-vm2) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-vm3) != 'y' ]];
do
	sleep 1s
done

rm -rf ${project_code}-vm1
rm -rf ${project_code}-vm2
rm -rf ${project_code}-vm3
    
# Grabbing IP Addresses
export VM_1_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query privateIps --output tsv)
export VM_2_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query privateIps --output tsv)
export VM_3_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name Bastion --query privateIps --output tsv)
export VM_1_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query publicIps --output tsv)
export VM_2_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query publicIps --output tsv)
export VM_3_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name Bastion --query publicIps --output tsv)







if [[ -z ${VM_1_Private_IP_ADDRESS} ]];
then
	echo && echo && echo && echo
	echo "Frontend VM Failed to Deploy."
	echo "${REGION} - was unable to deploy your VM, pick another Region"
	echo "Do you want to delete the failed resource group - ${RESOURCE_GROUP}"
	az group delete -n ${RESOURCE_GROUP} --force-deletion-types Microsoft.Compute/virtualMachines
	exit
fi
if [[ -z ${VM_2_Private_IP_ADDRESS} ]];
then
	echo && echo && echo && echo
	echo "Backend VM Failed to Deploy."
	echo "${REGION2} - was unable to deploy your VM, pick another Region"
	echo "Do you want to delete the failed resource group - ${RESOURCE_GROUP}"
	az group delete -n ${RESOURCE_GROUP} --force-deletion-types Microsoft.Compute/virtualMachines
	exit
fi
if [[ -z ${VM_3_Private_IP_ADDRESS} ]];
then
	echo && echo && echo && echo
	echo "Bastion VM Failed to Deploy."
	echo "${REGION2} - was unable to deploy your VM, pick another Region"
	echo "Do you want to delete the failed resource group - ${RESOURCE_GROUP}"
	az group delete -n ${RESOURCE_GROUP} --force-deletion-types Microsoft.Compute/virtualMachines
	exit
fi








tee ${project_code}-fe.sh << EOF
#!/bin/bash

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
-A INPUT -s ${VM_3_Private_IP_ADDRESS}/32 -p tcp --dport 22 -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p ${PROTOCOL} --dport ${ENDPORT} -m conntrack --ctstate NEW -j DNAT --to-destination ${VM_2_Private_IP_ADDRESS}
-A POSTROUTING -p ${PROTOCOL} --dport ${ENDPORT} -m conntrack --ctstate NEW -j SNAT --to-source ${VM_1_Private_IP_ADDRESS}
COMMIT
EOFFF

sudo iptables-restore /etc/iptables/rules.v4

# Enabling IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p
exit
EOF

tee ${project_code}-be.sh << EOF
#!/bin/bash
#
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
-A INPUT -s ${VM_3_Private_IP_ADDRESS}/32 -p tcp --dport 22 -j ACCEPT
COMMIT
*nat
:PREROUTING ACCEPT [0:0]
:INPUT ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
:POSTROUTING ACCEPT [0:0]
-A PREROUTING -p ${PROTOCOL} --dport ${ENDPORT} -m conntrack --ctstate NEW -j DNAT --to-destination ${ENDPOINT}:${ENDPORT}
-A POSTROUTING -p ${PROTOCOL} --dport ${ENDPORT} -m conntrack --ctstate NEW -j MASQUERADE
COMMIT
*filter
EOFFF

sudo iptables-restore /etc/iptables/rules.v4


# Enabling IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

exit
EOF

tee ${project_code}-bastion.sh << EOF
#!/bin/bash
#
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
-A POSTROUTING -d ${VM_1_Private_IP_ADDRESS}/32 -p TCP --dport 22 -m conntrack --ctstate NEW -j SNAT --to-source ${VM_3_Private_IP_ADDRESS}
-A POSTROUTING -d ${VM_2_Private_IP_ADDRESS}/32 -p TCP --dport 22 -m conntrack --ctstate NEW -j SNAT --to-source ${VM_3_Private_IP_ADDRESS}
COMMIT
*filter
EOFFF

sudo iptables-restore /etc/iptables/rules.v4


# Enabling IP Forwarding
sudo sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/g' /etc/sysctl.conf
sudo sysctl -p

exit
EOF
clear

ssh-keyscan -H ${VM_3_Public_IP_ADDRESS} >> ~/.ssh/known_hosts
scp -o StrictHostKeyChecking=no ${project_code}-bastion.sh azureuser@${VM_3_Public_IP_ADDRESS}:/tmp/
scp -o StrictHostKeyChecking=no -J azureuser@${VM_3_Public_IP_ADDRESS} ${project_code}-fe.sh azureuser@${VM_1_Private_IP_ADDRESS}:/tmp/
scp -o StrictHostKeyChecking=no -J azureuser@${VM_3_Public_IP_ADDRESS} ${project_code}-be.sh azureuser@${VM_2_Private_IP_ADDRESS}:/tmp/

clear
echo n > ${project_code}-ssh1
echo n > ${project_code}-ssh2
echo n > ${project_code}-ssh3

ssh -o StrictHostKeyChecking=no azureuser@${VM_3_Public_IP_ADDRESS} "sudo bash /tmp/${project_code}-bastion.sh && exit" && echo y > ${project_code}-ssh1 & \
ssh -o StrictHostKeyChecking=no -J azureuser@${VM_3_Public_IP_ADDRESS} azureuser@${VM_1_Private_IP_ADDRESS} "sudo bash /tmp/${project_code}-fe.sh && exit && sudo reboot" && echo y > ${project_code}-ssh2 & \
ssh -o StrictHostKeyChecking=no -J azureuser@${VM_3_Public_IP_ADDRESS} azureuser@${VM_2_Private_IP_ADDRESS} "sudo bash /tmp/${project_code}-be.sh && exit && sudo reboot" && echo y > ${project_code}-ssh3

clear

while [[ $(cat ${project_code}-ssh1) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-ssh2) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat ${project_code}-ssh3) != 'y' ]];
do
	sleep 1s
done

rm -rf ${project_code}-ssh1
rm -rf ${project_code}-ssh2
rm -rf ${project_code}-ssh3

rm -rf ${project_code}-bastion.sh
rm -rf ${project_code}-be.sh
rm -rf ${project_code}-fe.sh
clear
echo
echo -e " ${GREEN}Redirector complete:${NC}"
echo -e " Packets sent to ${GREEN}${VM_1_Public_IP_ADDRESS}:${ENDPORT} / ${PROTOCOL}${NC}"
echo -e "    will get ${RED}redirected to${NC} ${GREEN}${ENDPOINT}:${ENDPORT} / ${PROTOCOL}${NC}"
echo
echo -e " Your Bastion Host IP is: ${GREEN}${VM_3_Public_IP_ADDRESS}${NC}"
echo -e "     Frontend is accessible from the Bastion at ${GREEN}${VM_1_Private_IP_ADDRESS}${NC}"
echo -e "     Backend is accessible from the Bastion at ${GREEN}${VM_2_Private_IP_ADDRESS}${NC}"
echo
echo -e "   ${RED}SSH Keys are needed${NC}, if you lose them you can regenerate them on the Azure Portal"
echo -e "   By default the SSH key is utilizing ${GREEN}/home/${USER}/.ssh/id_rsa${NC} as the private key"
echo
echo -e " ${GREEN}Bastion Public IP${NC} is in the ${RED}same region as the backend IP${NC}"
echo
echo
