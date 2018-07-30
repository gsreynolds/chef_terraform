# Chef A2 Terraform

Consists of
* Chef Automate 2 server
* Chef Server
* Route53 DNS records

Currently only installing the packages and doing basic configuration - the rest is left as an exercise to the reader.

## Chef Server Manual Config
* Set data collector token from Automate server and configure Chef Server
  * `sudo chef-server-ctl set-secret data_collector token '<API_TOKEN>'`
  * `sudo chef-server-ctl restart nginx`
  * `sudo chef-server-ctl restart opscode-erchef`
  * Edit /etc/opscode/chef-server.rb and add:
    ```
    data_collector['root_url'] = 'https://automate.example.com/data-collector/v0/'
    # Add for chef client run forwarding
    data_collector['proxy'] = true
    # Add for compliance scanning
    profiles['root_url'] = 'https://automate.example.com'
    ```
  * `sudo chef-server-ctl reconfigure`
* Create a Chef Server organisation
  * `sudo chef-server-ctl org-create test TestOrg`
  * Copy the generated validator key for configuring unattended node registration
* Create a Chef Server user and associate it with the test org
  * `sudo chef-server-ctl user-create -p test admin Admin User admin@example.com -o test`
  * Copy the generated user client key for configuring knife on your workstation
* Grant the user Server Admin permissions (optional)
  * `sudo chef-server-ctl grant-server-admin-permissions admin`

## Validation
* Configure knife.rb
  ```
  # See http://docs.chef.io/config_rb_knife.html for more information on knife configuration options

  current_dir = File.dirname(__FILE__)
  log_level                :info
  log_location             STDOUT
  node_name                "admin"
  client_key               "#{current_dir}/admin.pem"
  chef_server_url          "https://chef.example.com/organizations/test"
  cookbook_path            ["#{current_dir}/../cookbooks"]
  ```
* Copy client key from Chef Server user-create command output to `admin.pem`
* `knife environment create production`
* `knife role create base`
* `knife environment show production`
* `knife role show base`
* Check Automate 2 Event Feed for environment & role updated events

## Unattended node registration
https://docs.chef.io/install_bootstrap.html#unattended-installs

* One option is to use AWS Systems Manager Parameter Store to make the validator securely available to nodes via IAM policy & roles
  * `aws ssm put-parameter --name "chef_validator" --type "SecureString" --overwrite --value "$(cat validator.pem)"`
* `chef_validator.tf` includes IAM config for allowing EC2 instances access to the validator key in SSM
* `chef_client_nodes.tf` includes an example of unattended node registration
