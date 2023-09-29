# Azure Regions:
# westus,eastus,northeurope,westeurope,eastasia,southeastasia,northcentralus
#southcentralus,centralus,eastus2,japaneast,japanwest,brazilsouth,australiaeast
#australiasoutheast,centralindia,southindia,westindia,canadacentral,canadaeast
#westcentralus,westus2,ukwest,uksouth,koreacentral,koreasouth,francecentral
#australiacentral,southafricanorth,uaenorth,switzerlandnorth,germanywestcentral
#norwayeast,westus3,jioindiawest,swedencentral,qatarcentral,polandcentral
#italynorth,israelcentral



#### Modify These Variables before starting ####
SUBSCRIPTION_NAME=s2vaus-sandbox-tactical
################################################




echo n > vm1
echo n > vm2
echo n > first_finished
echo n > second_finished



subnet_variable_reset() {
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

subnet_variable_check() {
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



subnet_builder_menu() {
	# This function will create a display for the end user to see what they have done
subnet_variable_check
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
echo " ###                                ##  Endpoint IP: ${ENDPOINT}"
echo " ###                                ##  Endpoint Port: ${ENDPORT}"
echo " ###                                ##  Endpoint Port: ${PROTOCOL}"
echo " ###                                ##  "
echo " #############################################################################"
echo " #############################################################################"
echo
}




subnet_builder_variables() {
	# This function will interact with the user to receive inputs
subnet_variable_reset
while [[ "${choice}" == N ]];
do
	subnet_builder_menu
	echo " What is your Azure Subscription ID for 'Sandbox Tactical' (########-####-####-####-############)?"
	read -p " > " SUBSCRIPTION
	subnet_builder_menu
	echo " What is your Project Name for your Resource Group (twister)?"
	read -p " > " PROJECT
	if [[ -z "${PROJECT}" ]];
	then
		PROJECT=twister
	fi
	subnet_builder_menu
	clear
	tee << EOF
 Azure Regions:
westus,eastus,northeurope,westeurope,eastasia,southeastasia,northcentralus
southcentralus,centralus,eastus2,japaneast,japanwest,brazilsouth,australiaeast
australiasoutheast,centralindia,southindia,westindia,canadacentral,canadaeast
westcentralus,westus2,ukwest,uksouth,koreacentral,koreasouth,francecentral
australiacentral,southafricanorth,uaenorth,switzerlandnorth,germanywestcentral
norwayeast,westus3,jioindiawest,swedencentral,qatarcentral,polandcentral
italynorth
EOF
	echo
	echo " What region is closest to your users (eastus)?"
	read -p " > " REGION
	if [[ -z "${REGION}" ]];
	then
		REGION=eastus
	fi
	subnet_builder_menu
	clear
	tee << EOF
 Azure Regions:
westus,eastus,northeurope,westeurope,eastasia,southeastasia,northcentralus
southcentralus,centralus,eastus2,japaneast,japanwest,brazilsouth,australiaeast
australiasoutheast,centralindia,southindia,westindia,canadacentral,canadaeast
westcentralus,westus2,ukwest,uksouth,koreacentral,koreasouth,francecentral
australiacentral,southafricanorth,uaenorth,switzerlandnorth,germanywestcentral
norwayeast,westus3,jioindiawest,swedencentral,qatarcentral,polandcentral
italynorth
EOF
	echo
	echo " What region do you want to pop out of (centralus)?"
	read -p " > " REGION2
	if [[ -z "${REGION2}" ]];
	then
		REGION2=centralus
	fi
	subnet_builder_menu
	echo " What is your endpoint IP to send users to i.e. 23.62.11.8?"
	read -p " > " ENDPOINT
	subnet_builder_menu
	echo " What Port is your endpoint using i.e. 443?"
	read -p " > " ENDPORT
	subnet_builder_menu
	echo " What protocol do you want i.e. TCP?"
	read -p " > " PROTOCOL
	subnet_builder_menu
	echo " Do these options look correct? [y/N]"
	read -p " > " choice
	if [[ "${choice}" != [y/Y] ]];
	then
		subnet_variable_reset
	fi

done
}
subnet_builder_variables


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
VMNAME=REDIR_FE
VMNAME2=REDIR_BE
VPN_PORT=${port}

output=$(az group show --name ${RESOURCE_GROUP} 2> /dev/null)
if [[ "${output}" == *Succeeded* ]];
then
	clear
 	echo "Resource Group Already Exists!"
  	echo "Please pick a different project name or region and try again"
   	echo
    	echo "Existing Resource Groups:"
    	az group list | grep name | cut -d '"' -f4
     	exit
fi

# Connect to Azure CLI
az account show
if ! [[ ${?} == 0 ]];
then
	az login
fi

# Connect to Azure Subscription
az account set -s ${SUBSCRIPTION}

# Create a new Resource Group
az group create \
    --name ${RESOURCE_GROUP} \
    --location ${REGION}
   
first_instance() {
az network vnet create \
    --name ${VNET1} \
    --resource-group ${RESOURCE_GROUP} \
    --address-prefix 10.0.0.0/16 \
    --subnet-name ${V_SUBNET1_NAME} \
    --location ${REGION} \
    --subnet-prefixes ${V_SUBNET1}
    
az network nsg create \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION} \
    --name ${NSG1}

az network nsg rule create \
    --resource-group ${RESOURCE_GROUP} \
    --nsg-name ${NSG1} \
    --name SSH-rule \
    --priority 300 \
    --destination-address-prefixes '*' \
    --destination-port-ranges 22 \
    --protocol Tcp \
    --description "Allow SSH"
      
az network nsg rule create \
    --resource-group ${RESOURCE_GROUP} \
    --nsg-name ${NSG1} \
    --name VPN-rule \
    --priority 310 \
    --destination-address-prefixes '*' \
    --destination-port-ranges ${ENDPORT} \
    --protocol ${PROTOCOL} \
    --description "Allow Redirector" 
        
az network public-ip create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC1_IP} \
    --sku Standard \
    --location ${REGION}

az network nic create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC1} \
    --vnet-name ${VNET1} \
    --location ${REGION} \
    --subnet ${V_SUBNET1_NAME} \
    --network-security-group ${NSG1} \
    --public-ip-address ${VNIC1_IP}

 
}

second_instance() {
az network vnet create \
    --name ${VNET2} \
    --resource-group ${RESOURCE_GROUP} \
    --address-prefix 10.1.0.0/16 \
    --subnet-name ${V_SUBNET2_NAME} \
    --location ${REGION2} \
    --subnet-prefixes ${V_SUBNET2}
    
az network nsg create \
    --resource-group ${RESOURCE_GROUP} \
    --location ${REGION2} \
    --name ${NSG2}

az network public-ip create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC2_IP} \
    --sku Standard \
    --location ${REGION2}

az network nic create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VNIC2} \
    --vnet-name ${VNET2} \
    --location ${REGION2} \
    --subnet ${V_SUBNET2_NAME} \
    --network-security-group ${NSG2} \
    --public-ip-address ${VNIC2_IP}


 
}

first_instance && echo y > first_finished & second_instance && echo y > second_finished

while [[ $(cat first_finished) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat second_finished) != 'y' ]];
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
az network vnet peering create \
  --name Peer_to_BE \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET1} \
  --remote-vnet $vNet2Id \
  --allow-vnet-access
  
az network vnet peering create \
  --name Peer_to_FE \
  --resource-group ${RESOURCE_GROUP} \
  --vnet-name ${VNET2} \
  --remote-vnet $vNet1Id \
  --allow-vnet-access

 
build_one() {
    
# Create VM
az vm create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VMNAME} \
    --location ${REGION} \
    --image "Ubuntu2204" \
    --size Standard_DS3_v2 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC1}
   }
   build_two() {
az vm create \
    --resource-group ${RESOURCE_GROUP} \
    --name ${VMNAME2} \
    --location ${REGION2} \
    --image "Ubuntu2204" \
    --size Standard_DS3_v2 \
    --admin-username azureuser \
    --generate-ssh-keys \
    --nics ${VNIC2}
   } 
   
build_one && echo y > vm1 & build_two && echo y > vm2

while [[ $(cat vm1) != 'y' ]];
do
	sleep 1s
done
while [[ $(cat vm2) != 'y' ]];
do
	sleep 1s
done
    
rm -rf first_finished
rm -rf second_finished
rm -rf vm1
rm -rf vm2

    
# Grabbing IP Addresses
export VM_1_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query privateIps --output tsv)
export VM_2_Private_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query privateIps --output tsv)
export VM_1_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME} --query publicIps --output tsv)
export VM_2_Public_IP_ADDRESS=$(az vm show --show-details --resource-group ${RESOURCE_GROUP} --name ${VMNAME2} --query publicIps --output tsv)

echo "VM 1: ${VMNAME}"
echo ${VM_1_Private_IP_ADDRESS}
echo ${VM_1_Public_IP_ADDRESS}

echo "VM 2: ${VMNAME2}"
echo ${VM_2_Private_IP_ADDRESS}
echo ${VM_2_Public_IP_ADDRESS}

vpn_ip=${VM_1_Public_IP_ADDRESS}


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

tee be_deployment_script.sh << EOF
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
-A INPUT -s ${VM_1_Private_IP_ADDRESS}/32 -p tcp --dport 22 -j ACCEPT
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
clear



ssh-keyscan -H ${VM_1_Public_IP_ADDRESS} >> ~/.ssh/known_hosts




scp -o StrictHostKeyChecking=no fe_deployment_script.sh azureuser@${VM_1_Public_IP_ADDRESS}:/tmp/
scp -o StrictHostKeyChecking=no -J azureuser@${VM_1_Public_IP_ADDRESS} be_deployment_script.sh ${server_name}_server.conf azureuser@${VM_2_Private_IP_ADDRESS}:/tmp/


clear
echo
echo
echo "############################################################################"
echo "############################################################################"
echo
echo "Copy and Paste the next line into the VPNFE SSH Session"
echo 
echo "sudo bash /tmp/fe_deployment_script.sh && logout"
echo 
echo "############################################################################"
echo "############################################################################"
echo
ssh -o StrictHostKeyChecking=no azureuser@${VM_1_Public_IP_ADDRESS}
clear
echo
echo
echo "############################################################################"
echo "############################################################################"
echo
echo "Copy and Paste the next line into the VPNBE SSH Session"
echo 
echo "sudo bash /tmp/be_deployment_script.sh && logout"
echo 
echo "############################################################################"
echo "############################################################################"
echo
ssh -o StrictHostKeyChecking=no -J azureuser@${VM_1_Public_IP_ADDRESS} azureuser@${VM_2_Private_IP_ADDRESS}

clear
rm -rf be_deployment_script.sh
rm -rf fe_deployment_script.sh
clear
echo "Redirector Built:"
echo "If you go to ${PROTOCOL}/${VM_1_Public_IP_ADDRESS}:${ENDPORT}"
echo "you will get redirected to"
echo "${PROTOCOL}/${ENDPOINT}:${ENDPORT}"

























