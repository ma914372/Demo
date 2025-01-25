# Outputs
output "master_node_ip" {
  value = aws_instance.kubernetes_master[*].public_ip
}

output "worker_node_ips" {
  value = aws_instance.kubernetes_worker_nodes[*].public_ip
}

output "ansible_node_ip" {
  value = aws_instance.ansible_node.public_ip
}

#output "elb_dns_name" {
  #value = aws_elb.kubernetes_elb.dns_name
#}
