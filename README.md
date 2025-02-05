Overview
This project uses the following tools and services:

. GitHub Actions for automating the deployment process.

. Terraform for provisioning AWS infrastructure.

. Ansible as configuration management to install Kubernetes(k3s), ArgoCD.

. Creating the reposititory connection with argocd then defining argocd application resource using yml.

. Creating webhook in gitops repo to automated the sync process.


The infrastructure includes:

. A VPC with subnets, associated with Internet Gateway, route table, security group, store statefile into s3 backend.

. EC2 instances for Kubernetes master and worker nodes.

. An Ansible node to manage the configuration of Kubernetes and ArgoCD.

. Necessary security groups.

. ArgoCD configuration for GitOps continuous delivery.


Commands to check:

. kubectl get secret argocd-initial-admin-secret -n argocd -o=jsonpath='{.data.password}' | base64 --decode

. kubectl get svc -n nginx

. kubectl get svc -n argocd

. kubectl get pods -o wide -n nginx

. systemctl status k3s

. systemctl status k3s-agent
