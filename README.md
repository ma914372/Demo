Overview
This project uses the following tools and services:

Terraform for provisioning AWS infrastructure.
Ansible for configuration management and deployment (Kubernetes, ArgoCD)
Shell script for triggering deployments via webhook.
GitHub Actions for automating the deployment process.

The infrastructure includes:
A VPC with subnets, associated with Internet Gateway and route tables.
EC2 instances for Kubernetes master and worker nodes.
An Ansible node to manage the configuration of Kubernetes and ArgoCD.
Necessary security groups.
ArgoCD configuration for GitOps continuous delivery.

How to use:
Clone the repository
git clone https://github.com/ma914372/Demo.git
