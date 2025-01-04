# create an instance
resource "aws_instance" "instance" {
  ami = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.security_group.id]
  availability_zone = var.availability_zones
  subnet_id = var.subnet_id[0]
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
    }
  }
  tags = {
    Name = "${var.env}-${var.component}-demo"
  }
}
# create a security group
resource "aws_security_group" "security_group" {
  name        = "${var.env}-sg"
  vpc_id      = var.vpc_id
  ingress {
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "TCP"
    cidr_blocks      = var.server_app_port

  }
  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = var.bastion_nodes
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  tags = {
    Name = "${var.env}-sg"
  }
}
# create a provisioner
resource "null_resource" "null_instance" {
  connection {
    type     = "ssh"
    user     = jsondecode(data.vault_generic_secret.my_secret.data_json).username
    password = jsondecode(data.vault_generic_secret.my_secret.data_json).password
    host     = aws_instance.instance.private_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo dnf install ansible -y",
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost, -U https://github.com/devps23/expense-practice-ansible get-secrets.yml -e env=${var.env} -e component_name=${var.component} -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/devps23/expense-practice-ansible expense.yml -e env=${var.env} -e component_name=${var.component} -e @~/secrets.json -e @~/app.json"
    ]
  }
}
resource "aws_route53_record" "server_record" {
  count = var.lb_needed ? 0 : 1
  name      = "${var.env}-${var.component}-dns"
  type      = "A"
  zone_id   = var.zone_id
  ttl       = 5
  records = [aws_instance.instance.private_ip]
}
resource "aws_route53_record" "lb_record" {
  count = var.lb_needed ? 1 : 0
  name      = "${var.env}-${var.component}-dns"
  type      = "CNAME"
  zone_id   = var.zone_id
  ttl       = 5
  records = [aws_lb.lb[0].dns_name]
}
# create load balancer
resource "aws_lb" "lb" {
  count             = var.lb_needed ? 1 : 0
  name               = "${var.env}-${var.component}-lb"
  internal           = var.lb_type == "public" ? false : true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb_security_group[0].id]
  subnets            = var.lb_subnets
  tags = {
    Environment = "${var.env}-${var.component}-lb"
  }
}
# create a target group
resource "aws_lb_target_group" "tg" {
  count             = var.lb_needed ? 1 : 0
  name              = "${var.env}-${var.component}-tg"
  port              = var.app_port
  protocol          = "HTTP"
  vpc_id            = var.vpc_id
  health_check {
    protocol = "HTTP"
    port = var.app_port
    path = "/health"
    healthy_threshold = 2
    unhealthy_threshold = 2
    interval = 5
    timeout = 2
  }
}
# create a target group attachment
resource "aws_lb_target_group_attachment" "tg_attach" {
  count             = var.lb_needed ? 1 : 0
  target_group_arn = aws_lb_target_group.tg[0].arn
  target_id        = aws_instance.instance.id
  port             = var.app_port
}
# create a listeners
# create listeners and forward target groups to load balancer
resource "aws_lb_listener" "lb_listener" {
  count             = var.lb_needed ? 1 : 0
  load_balancer_arn = aws_lb.lb[0].arn
  port              = var.app_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg[0].arn
  }
}
# create a security loadbalancer
resource "aws_security_group" "lb_security_group" {
  count              = var.lb_needed ? 1:0
  name               = "${var.env}-lsg"
  vpc_id             = var.vpc_id
  ingress {
    from_port        = var.app_port
    to_port          = var.app_port
    protocol         = "TCP"
    cidr_blocks      = var.lb_app_port
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.env}-lsg"
  }
}


