

#################################################################

# resources

#################################################################

# NETWORKING #


 
resource "aws_vpc" "terraform-vpc" 
{
	cidr_block = "${var.network_address_space}"
	enable_dns_hostnames = "true" 


	tags {
	  Name = "${var.env}-vpc"
	  
	  Environment  = "${var.env}"
	}
}

resource "aws_internet_gateway" "igw" {
	vpc_id = "${aws_vpc.terraform-vpc.id}"

	  tags {
	     Name = "${var.env}-igw"
	 
	     Environment  = "${var.env}"
	  }
}

resource "aws_subnet" "subnet1" {
	cidr_block              = "${var.subnet1_address_space}"
	vpc_id                  = "${aws_vpc.terraform-vpc.id}"
	map_public_ip_on_launch = "true"
	availability_zone = "${data.aws_availability_zones.available.names[0]}"

	tags {
	     Name = "${var.env}-subnet1"
	     
	     Environment  = "${var.env}"
	  }



}

resource "aws_subnet" "subnet2" {
	cidr_block              = "${var.subnet2_address_space}"
	vpc_id                  = "${aws_vpc.terraform-vpc.id}"
	map_public_ip_on_launch = "true"
	availability_zone = "${data.aws_availability_zones.available.names[1]}"

	 tags {
	     Name = "${var.env}-subnet2"
	     
	     Environment  = "${var.env}"
	  }

}



# ROUTING #

resource "aws_route_table" "rtb" {
	vpc_id   = "${aws_vpc.terraform-vpc.id}"

	route {
	  cidr_block = "0.0.0.0/0"
	  gateway_id = "${aws_internet_gateway.igw.id}"
	}

	 tags {
	   Name = "{var.env}-rtb"
	   
	   Environment  = "${var.env}"
	 }


}

resource "aws_route_table_association" "rta-subnet1" {
	 subnet_id      = "${aws_subnet.subnet1.id}"
	 route_table_id  = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-subnet2" {
	 subnet_id      = "${aws_subnet.subnet2.id}"
	 route_table_id  = "${aws_route_table.rtb.id}"
}



# SECURITY GROUPS #

# ELB Security group

resource "aws_security_group" "elb_sg" {
	name      = "ngix_elb_sg"
	vpc_id     = "${aws_vpc.terraform-vpc.id}"

# SSH access from Anywhere

ingress {
	from_port     = 22
	to_port       = 22
	protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
   }

# HTTP access from anywhere

ingress {
	from_port     = 80
	to_port       = 80
	protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
   }

# Outbound Internet access

egress {
	from_port     = 0
	to_port       = 0
	protocol      = "-1"
    cidr_blocks   = ["0.0.0.0/0"]
  }
    
    tags {
	   Name = "{var.env}-sg"
	   
	   Environment  = "${var.env}"
	 }


}

# Nginx Security group

resource "aws_security_group" "nginx_sg" {
	name      = "nginx_sg"
	vpc_id     = "${aws_vpc.terraform-vpc.id}"

# SSH access from Anywhere

ingress {
	from_port     = 22
	to_port       = 22
	protocol      = "tcp"
    cidr_blocks   = ["0.0.0.0/0"]
   }

# HTTP access from anywhere

ingress {
	from_port     = 80
	to_port       = 80
	protocol      = "tcp"
    cidr_blocks   = ["${var.network_address_space}"]
   }

# Outbound Internet access

egress {
	from_port     = 0
	to_port       = 0
	protocol      = "-1"
    cidr_blocks   = ["0.0.0.0/0"]
  }

     tags {
	   Name = "{var.env}-nginx-sg"
	 
	   Environment  = "${var.env}"
	 }


}





# INSTANCES #

resource "aws_instance" "nginx1" {
	
	ami           = "ami-0a34f2d854bdbd4fb"
	instance_type = "${lookup(var.instance_type,var.env)}"
	subnet_id     = "${aws_subnet.subnet1.id}"
	vpc_security_group_ids = ["${aws_security_group.nginx_sg.id}"]
	key_name      = "${var.key_name}"

	 

	      tags {
	   Name = "${var.env}-nginx1"
	  
	   Environment  = "${var.env}"
	 }
  
	     
}


resource "aws_instance" "nginx2" {
	
	ami           = "ami-0a34f2d854bdbd4fb"
	instance_type = "${lookup(var.instance_type,var.env)}"
	subnet_id     = "${aws_subnet.subnet2.id}"
	vpc_security_group_ids = ["${aws_security_group.nginx_sg.id}"]
	key_name      = "${var.key_name}"

	 

	      tags {
	   Name = "${var.env}-nginx2"
	  
	   Environment  = "${var.env}"
	 }
  
	     
}

# LOAD BALANCER #

resource "aws_elb" "web" {
	name = "terraform-elb"

	subnets = ["${aws_subnet.subnet1.id}", "${aws_subnet.subnet2.id}"]
	security_groups = ["${aws_security_group.elb_sg.id}"]
	instances = ["${aws_instance.nginx1.id}", "${aws_instance.nginx2.id}"]

	listener {
	   instance_port     = 80
	   instance_protocol = "http"
	   lb_port           = 80
	   lb_protocol       = "http"
	   
	     }


	      tags {

	   Name = "${var.env}-elb"
	   
	   Environment  = "${var.env}"
	      }
}




#    S3 BUCKET     #

resource "aws_s3_bucket" "terraform-bucket" {
	
	bucket = "${var.env}-${var.bucket_name}"
	acl  = "private"
	force_destroy = "true"

	 tags {

	   Name = "${var.env}-bucket"
	   
	   Environment  = "${var.env}"
	      }

}


#################################################################

# output

#################################################################
   
   output "aws_instance_public_dns" {

     value = "${aws_instance.nginx1.public_dns}"
   }
