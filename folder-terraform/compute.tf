# 1. Fetch the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}
# 2. Key Pair for SSH Access
resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

/*# 3. Public Web Server
resource "aws_instance" "web_server" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = "t3.micro" # Free-tier eligible
  subnet_id              = aws_subnet.public[0].id
  vpc_security_group_ids = [aws_security_group.public_web_sg.id]
  key_name               = aws_key_pair.deployer.key_name

  # Bootstrap script to install a web server
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Phase 1 Complete! Web server is running in AWS.</h1>" > /var/www/html/index.html
              EOF

  tags = {
    Name        = "${var.project_name}-web-server"
    Environment = var.environment
  }
}*/
