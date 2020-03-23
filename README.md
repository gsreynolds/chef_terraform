# Chef A2 Terraform

Consists of
* Application Load Balancer
* Chef Automate 2 server
* Chef Server standalone or Chef HA Frontend/Backend clusters
* Route53 DNS records
* Org and admin user creation
* Chef Clients

Currently only installing the packages and doing minimal configuration - the rest is left as an exercise to the reader.

## Load Balancer - `chef_alb`
Uses the terraform-aws-modules/alb/aws module to create a ALB with a certificate issued from ACM to serve traffic to Chef Automate and Chef Server/Chef HA.

## Chef Automate - `chef_automate2`
Installs Chef Automate and retrieves credentials & data collector token.
https://automate.chef.io/docs/install/

## Chef Server
Installs Chef Server Standalone or with Frontend & Chef-Backend servers.

### Standalone - `chef_server`
https://docs.chef.io/install_server/#standalone

### Chef HA Frontend and Backend Config - `chef_ha`
https://docs.chef.io/install_server_ha/

## Org and user creation - `test_org_setup`
Creates a `test` org and `admin` user.

## Chef Clients

### Chef Client module  - `chef_clients`
Installs and configures Chef Client.

One option is to use AWS Systems Manager Parameter Store to make the validator securely available to nodes via IAM policy & roles
* `chef_unattended_registration` includes IAM config for allowing EC2 instances access to the validator key in SSM
* `chef_clients` includes an example of unattended node registration: https://docs.chef.io/install_bootstrap/#unattended-installs

Another option is to use the Terraform Chef provisioner
* `chef_clients` also includes an example of using the Chef provisioner: https://www.terraform.io/docs/provisioners/chef.html

### Effortless Chef Client module - `effortless_clients`
Uses pre-built Chef Habitat "Effortless Config" packages, which bundle Chef Client and a Policyfile in a Habitat package: https://github.com/chef/effortless & https://learn.chef.io/modules/effortless-config#/demos-and-quickstarts
