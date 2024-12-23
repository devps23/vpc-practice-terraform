# create an instance
resource "aws_instance" "instance" {
  ami = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.security_group.id]
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
    from_port        = 22
    to_port          = 22
    protocol         = "TCP"
    cidr_blocks      = ["0.0.0.0/0"]

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
resource "null_resource" "null_instance" {
  connection {
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
    host     = aws_instance.instance.public_ip
  }
  provisioner "remote-exec" {
    inline = [
      "sudo pip3.11 install ansible hvac",
      "ansible-pull -i localhost. -U https://github.com/pdevpos/learn-ansible get_secrets_vault.yml -e env=${var.env} -e component_nam=${var.component} -e vault_token=${var.vault_token}",
      "ansible-pull -i localhost, -U https://github.com/pdevpos/learn-ansible expense.yml -e env=${var.env} -e component_name=${var.component} -e @secrets.json -e @app.json"
    ]
  }
}
resource "aws_route53_record" "vault_record" {
  name      = "vault_internal"
  type      = "A"
  zone_id   = var.zone_id
  ttl       = 5
  records = [aws_instance.instance.public_ip]
}


