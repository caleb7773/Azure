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
<i>git clone https://github.com/caleb7773/Bipittybop.git</i>
#### Enter the directory and run one of the two scripts
<i>cd Bipittybop<br></i>
<br>
### To Deploy a simple Redirectory type:
<i>bash Azure_Redirector.sh</i>
<br>
### To Deploy a simple VPN Server type:
<i>bash Azure_VPN_Server.sh</i>
