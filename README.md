# Deploying Azure VPN Server and Redirectors

### Configured and Tested using Ubuntu 22.04 Virtual Machine
Please be a gem and don't try anything else...
<br><br>
#### Update your Machine
```
sudo apt update -y && sudo apt upgrade -y
```
#### Install GIT
```
sudo apt install git -y
```
#### Install Azure CLI
```
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```
#### Clone Github Repo
```
cd ~
git clone https://github.com/caleb7773/Azure.git
```
#### Enter the directory and run one of the two scripts
```
cd Azure
```
### To Deploy a simple Redirectory type:
bash Azure_Redirector.sh
<br>
### To Deploy a simple VPN Server type:
bash Azure_VPN_Server.sh
