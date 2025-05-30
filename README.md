# azure-tf-epodv2
This repo provides an example to create the necessary azure infrastructure for deployment of epods v2 on azure kubernetes service (aks). This feature (SAI epods v2 BYOK) is presently a wip (and features like auto-update and external statefulsets are in pipeline) and require support to enable epodsv2 on the SAI tenant from BOP. Provided as-is, only for demo/training purposes.

This script will setup an aks instance and a jumpbox-vm to connect to the aks using kubectl. It will then use the SAI APIs to create an epodv2 appliance, and download the helm charts, overrides.yaml and repository secret needed for the installation. See epodv2 documentation [here](https://docs.securiti.ai/modules/appliances/en/securiti-pods-and-elastic-pods/elastic-pod-v2-private-preview.html). 

## Prerequisites
The script needs terraform and azure cli to run. These can be installed using a packet manager like apt (linux) or using homebrew (mac). We will create a jumpbox machine on azure first to download the helm charts and perform the install on aks. 

NOTE: These are mac instructions (homebrew --> azure cli --> terraform --> jumpbox-machine, aks, redis, helm based install). Provided as-is. 

```shell
#install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
## install terraform
brew install terraform
## install az cli
brew install azure-cli
$> az login
$> git clone https://github.com/amitgupta7/azure-tf-epodv2.git
$> source tfAlias
## Create terraform tfvars file, see format below
$> vi terraform.tfvars
$> tf init
$> tfaa
## clean-up
$> tfda
```

Create a `terraform.tfvars` file to proivide azure subscription id, existing resource group And/Or other inputs to the script. See `var.tf` file for more details. e.g.
```hcl
az_subscription_id = "your-azure-subscription-id"
az_resource_group  = "existing-resource-group-in-azure"
az_name_prefix     = "unique-prefix-to-use-in-resource-names"
X_API_Secret       = "sai api secret"
X_API_Key          = "sai api key"
X_TIDENT           = "sai api tenant"
azpwd              = "some secure password atleast 16 char 3-outof-4 of alpha-num-caps-special"
pod_owner          = "SAI portal admin email address"
client_ip          = "Laptop ip address, use `curl ifconfig.me`"
```
##  Outputs
Use the output to ssh into the jumpbox. 
```shell
Outputs:

ssh_credentials = <<EOT
ssh -L 8800:localhost:8800 azuser@azure-tf-epod1-amit-jumpbox.westus2.cloudapp.azure.com 
with password: <your_super_secure_password>
EOT
```