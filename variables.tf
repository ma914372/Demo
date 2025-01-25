variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "CIDR for VPC"
}

variable "region" {
    description = "Pass the required region"
    type = string
    default = "us-east-1"
}

variable "subnet_cidr" {
    description = "CIDR for subnet"
    default = "10.0.1.0/24"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "my-key" {
  description = "Name of the SSH key pair"
}

variable "ami_id" {
  description = "Amazon Linux AMI ID"
}
