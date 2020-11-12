variable "aws_access_key" {
  type        = string
  description = "AWS access key used to create infrastructure"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key used to create AWS infrastructure"
}

variable "aws_region" {
  type        = string
  description = "AWS region used for all resources"
}

variable "availability_zone" {
  type        = string
  description = "AWS availability zone used for all instances"
}

variable "aws_key_name" {
  type        = string
  description = "AWS Key used for all resources"
}

variable "linux_master_instance_type" {
  type        = string
  description = "Instance type used for all Rancher cp/etc instances"
}

variable "linux_worker_instance_type" {
  type        = string
  description = "Instance type used for all Rancher Linux worker instances"
}

variable "windows_worker_instance_type" {
  type        = string
  description = "Instance type used for all Rancher Windows worker instances"
}

variable "num_linux_master" {
  type        = string
  description = "Number of Rancher Linux Master (etcd and controlplane role) nodes to provision" 
  default     = "3"
}

variable "num_linux_worker" {
  type        = string
  description = "Number of Rancher Linux Worker nodes to provision" 
  default     = "1"
}

variable "num_windows_worker" {
  type        = string
  description = "Number of Rancher Windows worker nodes to provision" 
  default     = "1"
}

variable "owner" {
  type        = string
  description = "Owner name for AWS instances"
}

variable "prefix" {
  type        = string
  description = "Owner name for AWS instances"
}

variable "private_key_path" {
  type        = string
  description = "local private key path for AWS key used to ssh to linux and decrypt windows passwords"
}

variable "ssh_user_linux" {
  type        = string
  description = "ssh user for linux aws instances"
  default     = "ubuntu"
}

variable "ssh_user_windows" {
  type        = string
  description = "ssh user for windows aws instances"
  default     = "administrator"
}

variable "userdata_linux_file" {
  type        = string
  description = "path to local userdata file for linux aws instances"
  default     = "userdata_linux.txt"
}

variable "userdata_windows_file" {
  type        = string
  description = "path to local userdata file for windows aws instances"
  default     = "userdata_windows.txt"
}


variable "linux_master_volume_size" {
    description = "linux master aws root block device volume size in GB"
    default = 50
}

variable "linux_worker_volume_size" {
    description = "linux worker aws root block device volume size in GB"
    default = 50
}

variable "windows_worker_volume_size" {
    description = "windows worker aws root block device volume size in GB"
    default = 50
}


# rancher2 provider variables

variable "rancher_api_endpoint" {
  type        = string
  description = "Endpoint for the Rancher API"
}

variable "rancher_api_token" {
  type        = string
  description = "API Token to access the Rancher API"
}

variable "rancher_cluster_name" {
  type        = string
  description = "Name of the rancher cluster that's being created"
}


# networking

variable "vpc_id" {
  description = "vpc id for all resources"
}

variable "vpc_name" {
  description = "aws vpc name"
}

variable "sg_id" {
  description = "aws security group ID"
}

variable "subnet_id" {
  description = "aws security group ID"
}

variable "subnet_cidr_block" {
  description = "aws subnet cidr block"
}

variable "subnet_tag_name" {
  description = "name of the aws subnet"
}