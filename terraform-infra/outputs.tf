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

output "sonarqube_public_ip" {
  value = aws_instance.servers["sonarqube"].public_ip
}

output "sonarqube_url" {
  value = "http://${aws_instance.servers["sonarqube"].public_ip}:9000"
}

output "nexus_public_url" {
  value = "http://${aws_instance.servers["nexus"].public_ip}:8081"
}

output "nexus_private_ip" {
  value = aws_instance.servers["nexus"].private_ip
}

output "k8s_master_public_ip" {
  value = one([
    for k, inst in aws_instance.servers :
    inst.public_ip if inst.tags["Role"] == "k8s-master"
  ])
}

output "k8s_master_private_ip" {
  value = one([
    for k, inst in aws_instance.servers :
    inst.private_ip if inst.tags["Role"] == "k8s-master"
  ])
}


