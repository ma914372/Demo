output "master_node_ip" {
  value = aws_instance.kubernetes_master.public_ip
}

output "worker_node_ips" {
  value = join(",", [for ip in aws_instance.kubernetes_worker_nodes : ip.public_ip])
}

output "ansible_node_ip" {
  value = aws_instance.ansible_node.public_ip
}
output "master_private_ip" {
  value = aws_instance.kubernetes_master.private_ip
}

output "worker_private_ips" {
  value = join(",", [for ip in aws_instance.kubernetes_worker_nodes : ip.private_ip])
}







