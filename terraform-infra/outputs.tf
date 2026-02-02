output "bastion_public_ip" {
  value       = var.create_bastion ? aws_instance.bastion[0].public_ip : null
  description = "SSH into Bastion using this public IP"
}

output "private_ips" {
  value = { for k, v in aws_instance.servers : k => v.private_ip }
}

output "ssh_via_bastion_examples" {
  value = var.create_bastion ? {
    for k, v in aws_instance.servers :
    k => "ssh -i <KEY.pem> -J ubuntu@${aws_instance.bastion[0].public_ip} ubuntu@${v.private_ip}"
  } : {}
}
