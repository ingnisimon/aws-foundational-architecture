# 1. Public Web Security Group
resource "aws_security_group" "public_web_sg" {
  name        = "${var.project_name}-public-web-sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = aws_vpc.main.id

  # Inbound Rules (Ingress)
  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Best practice: Restrict to your home/office IP
  }

  # Outbound Rules (Egress)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # -1 means all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-public-web-sg"
    Environment = var.environment
  }
}
# 2. Private Database Security Group
resource "aws_security_group" "private_db_sg" {
  name        = "${var.project_name}-private-db-sg"
  description = "Allow MySQL inbound traffic from the web tier"
  vpc_id      = aws_vpc.main.id

  lifecycle {
    create_before_destroy = true
  }

  ingress {
    description     = "MySQL access from Web Server SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.public_web_sg.id]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.project_name}-private-db-sg"
    Environment = var.environment
  }
}
