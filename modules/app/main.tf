# create an instance
resource "aws_instance" "component" {
  ami = data.aws_ami.ami.image_id
  instance_type = var.instance_type
  vpc_id =  var.vpc_id
  subnet_id = var.subnet_id
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "stop"
      spot_instance_type             = "persistent"
    }
  }
  tags = {
    Name = "${var.env}-demo"
  }
}
