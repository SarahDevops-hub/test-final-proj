# variables.tf

variable "aws_region" {
  description = "AWS region"
  default     = "eu-west-3" 
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Subnet CIDR block"
  default     = "10.0.1.0/24"
}

variable "availability_zone" {
  description = "AWS Availability Zone"
  default     = "eu-west-3a" 
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  default     = "ami-031e7dbab5571668f" 
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.medium" 
}
