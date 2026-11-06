# 1. EC2 Launch Template
resource "aws_launch_template" "app_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.amazon_linux_2023.id
  instance_type = "t3.micro"
  key_name      = aws_key_pair.deployer.key_name

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.public_web_sg.id]
  }

  user_data = base64encode(<<-EOF
              #!/bin/bash
              dnf update -y
              dnf install -y httpd mariadb105
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Phase 2 Complete! Traffic routed via ASG and ALB.</h1>" > /var/www/html/index.html
              EOF
  )

  tags = {
    Name        = "${var.project_name}-launch-template"
    Environment = var.environment
  }
}
# 2. Auto Scaling Group
resource "aws_autoscaling_group" "app_asg" {
  name                = "${var.project_name}-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.app_tg.arn]
  min_size            = 1
  max_size            = 3
  desired_capacity    = 2

  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  # ASG tags must use this specific format to apply to the EC2 instances
  tag {
    key                 = "Name"
    value               = "${var.project_name}-asg-web-server"
    propagate_at_launch = true
  }
}
