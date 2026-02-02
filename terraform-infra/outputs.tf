output "public_ips" {
  value = { for k, inst in aws_instance.servers : k => inst.public_ip }
}

output "private_ips" {
  value = { for k, inst in aws_instance.servers : k => inst.private_ip }
}

output "ssh_commands" {
  value = {
    for k, inst in aws_instance.servers :
    k => "ssh -i my-project.pem ubuntu@${inst.public_ip}"
  }
}
