# VARIABLES #

variable "aws_access_key" {
	
}
variable "aws_secret_key" {
	
}
variable "aws_region" {}
variable "env" {
	
}

variable "key_name" {
	default = "project"
} 

variable "network_address_space" {
	default = "10.1.0.0/16"
}

variable "subnet1_address_space" {
	default = "10.1.0.0/24"
}

variable "subnet2_address_space" {
	default = "10.1.1.0/24"
}



variable "instance_type" {
	type = "map"
	default={
	 dev = "t2.micro"
	 qa = "t2.medium"
	}
}

variable "bucket_name" {}
