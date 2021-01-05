# terraform-modules

## Rancher2 AWS Windows Cluster
Terraform module to create a windows cluster in Rancher2 by doing the following.
* Create new custom cluster in Rancher2
* Creates vpc/subnets/security groups for new nodes
* Create 3 nodes in AWS (1 etcd/controlplane, 1 linux worker, 1 windows worker)
* Connects to each node via SSH and runs the agent command

### Usage
Requires working Rancher2 instance and AWS secret/key credentials profile in ~/.aws/credentials.
Change directory into rancher_windows_cluster, get your variables files in order (see below) and then run
`tf init` and `tf apply`. Use cluster as desired and when complete run `tf destroy` to get rid of all resources.


### Variables Files
Copy `default.auto.tfvars.example` to `default.auto.tfvars` and set your configuration there

Example:
```hcl
#### Variable definitions
vpc_name             = "vpc-name"
vpc_domain_name      = "" #leave blank for aws default
prefix               = "" #prefix for instance names
owner                = "" #owner tag value
aws_region           = "us-west-2"
aws_key_name         = "aws-key-name"
private_key_path     = "~/.ssh/aws-key-name.pem"
rancher_api_endpoint = "https://127.0.0.1:8080"
rancher_cluster_name = "cluster-name"
rancher_api_token    = "token-xxxx:<token>" # or use login.ps1 to generate
```

### Rancher2 Token
If you want to generate a token dynamically use login.ps1. 
Usage: `./login.ps1 rancher2.url username password`

This script generates `token.auto.tfvars` which includes a populated `rancher_api_token` variable.
