# Chef Terraform (AWS)

Consists of
* Application Load Balancer 
* Chef Automate 2 server
* Chef Server standalone or Chef HA Frontend/Backend clusters
* Route53 DNS records
* Org and admin user creation 
* Unattended client registration using SSM parameter for validator key
* Chef Clients

Tested versions (see `terraform.tfvars.example`):
* Chef Infra Server `14.0.58` (standalone and frontend for backend HA)
* Chef Backend `2.2.0`
* Chef Infra Client `16.5.77`

## Modules

### Load Balancer - `chef_alb`

Uses the terraform-aws-modules/alb/aws module to create a ALB with a certificate issued from ACM to serve traffic to Chef Automate and Chef Server/Chef HA.

### Chef Automate - `chef_automate2`

Installs Chef Automate and retrieves credentials & data collector token.

https://docs.chef.io/automate/install/

### Chef Server

Installs Chef Server Standalone or with Frontend & Chef-Backend servers.

#### Standalone - `chef_server`

https://docs.chef.io/install_server/#standalone

#### Chef HA Frontend and Backend Config - `chef_ha`

https://docs.chef.io/install_server_ha/

### Org and user creation - `test_org_setup`

Creates a `test` org and `admin` user. Creates SSM parameter to make `test` org validator key accessible to clients.

### Unattended registration - `chef_unattended_registration`

Allow nodes to self-register with Chef Server unattended via SSM parameter for validation key

### Chef Clients

#### Chef Client module  - `chef_clients`

Installs and configures Chef Client.

Use AWS Systems Manager Parameter Store to make the validator securely available to nodes via IAM policy & roles
* `chef_unattended_registration` includes IAM config for allowing EC2 instances access to the validator key in SSM
* `chef_clients` includes an example of unattended node registration: https://docs.chef.io/install_bootstrap/#unattended-installs

#### Effortless Chef Client module - `effortless_clients`

Uses pre-built Chef Habitat "Effortless Config" packages, which bundle Chef Client and a Policyfile in a Habitat package: https://github.com/chef/effortless
