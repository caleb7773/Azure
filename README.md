# Deploying Azure VPN Server and Redirectors

### Configured and Tested using Ubuntu 22.04 Virtual Machine
Please be a gem and don't try anything else...
<br><br>
#### Update your Machine
```
sudo apt update -y && sudo apt upgrade -y
```
#### Install GIT and Curl and OpenVPN
```
sudo apt install openvpn git curl -y
```
#### Install Azure CLI
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
#### Clone Github Repo and enter Directory
```
cd ~
git clone https://github.com/caleb7773/Azure.git
cd Azure
```
<br><br><br>
#### Run Script!
```
bash runner.sh
```

<br><br><br>
#### If you want to SSH into your servers do the following!
```
touch ~/.ssh/config
chmod 600 ~/.ssh/config

for i in {1..40}; do echo; done

read -p "Copy your Bastion Host IP here: " bastion_IP

tee -A ~/.ssh/config << EOF
Host redirector-frontend
        hostname 10.0.101.4
        user azureuser
        IdentityFile ~/.ssh/id_rsa
        ProxyJump redirector-bastion

Host redirector-backend
        hostname 10.1.102.5
        user azureuser
        IdentityFile ~/.ssh/id_rsa
        ProxyJump redirector-bastion

Host redirector-bastion
        hostname ${bastion_IP}
        user azureuser
        IdentityFile ~/.ssh/id_rsa
EOF
```
