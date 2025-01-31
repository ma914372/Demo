variable "vpc_cidr" {
  type        = string
  default     = "10.30.0.0/16"
  description = "CIDR for VPC"
}

variable "region" {
    description = "Pass the required region"
    type = string
    default = "us-east-1"
}


variable "subnet_cidr" {
    description = "CIDR for subnet"
    default = "10.30.1.0/24"
}

variable "subnet_cidr_ansible" {
  description = "CIDR block for Ansible Subnet"
  type        = string
  default = "10.30.4.0/24"
}

variable "instance_type" {
  default = "t2.medium"
  
}

variable "my-key" {
  description = "Name of the SSH key pair"
  default = "my-key"
}

variable "ami_id" {
  description = "Amazon Linux AMI ID"
  default = "ami-04b4f1a9cf54c11d0"
}
