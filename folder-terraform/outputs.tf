output "web_server_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "The public DNS of the web server"
  value       = aws_instance.web_server.public_dns
}
