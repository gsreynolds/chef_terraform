# Chef A2 Terraform

Consists of
* Chef Automate 2 server
* Chef Server standalone or Chef HA Frontend/Backend clusters
* Route53 DNS records
* Application Load Balancer

Currently only installing the packages and doing minimal configuration - the rest is left as an exercise to the reader.

## Load Balancer - chef_alb
Uses the terraform-aws-modules/alb/aws module to create a ALB with a certificate issued from ACM to serve traffic to Chef Automate and Chef Server/Chef HA.

## Chef Automate - chef_automate2
https://automate.chef.io/docs/install/

## Chef Server Standalone - chef_server
### Config
https://docs.chef.io/install_server/#standalone

## Chef HA - chef_ha
### Frontend Config
https://docs.chef.io/install_server_ha/

### Backend Config
https://docs.chef.io/install_server_ha/

### Backend failure recovery
https://docs.chef.io/backend_failure_recovery/

## Chef Clients
### Chef Client module  - chef_clients
### Effortless Chef Client module - effortless_clients

## Unattended node registration - chef_unattended_registration
https://docs.chef.io/install_bootstrap/#unattended-installs

* One option is to use AWS Systems Manager Parameter Store to make the validator securely available to nodes via IAM policy & roles
* `chef_unattended_registration` includes IAM config for allowing EC2 instances access to the validator key in SSM
* `chef_clients` includes an example of unattended node registration. `chef_clients.count` variable controls how many clients are deployed.
