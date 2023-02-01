output "aws_vpc" {
  description = "Default VPC"
  value       = split("/", split(":", data.aws_vpc.default.arn)[5])[1]
}

output "aws_subnets" {
  description = "aws_subnets"
  value       = data.aws_subnets.all.ids
}
