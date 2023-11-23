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
