# Deploying Azure VPN Server and Redirectors

### Configured and Tested using Ubuntu 22.04 Virtual Machine
Please be a gem and don't try anything else...
<br><br>
#### Update your Machine
<i>sudo apt update -y && sudo apt upgrade -y</i>
#### Install GIT
<i>sudo apt install git -y</i>
#### Install Azure CLI
<i>curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash</i>
#### Clone Github Repo
<i>cd ~<br></i>
<i>git clone https://github.com/caleb7773/Azure.git</i>
#### Enter the directory and run one of the two scripts
<i>cd Azure<br></i>
<br>
### To Deploy a simple Redirectory type:
bash Azure_Redirector.sh
<br>
### To Deploy a simple VPN Server type:
bash Azure_VPN_Server.sh


```
function test() {
  console.log("This code will have a copy button to the right of it");
}
```
