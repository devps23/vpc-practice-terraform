output "vpc_id" {
  value = aws_vpc.vpc.id
}
output "frontend_subnet"{
  value = aws_subnet.frontend_subnets.*.id
}
