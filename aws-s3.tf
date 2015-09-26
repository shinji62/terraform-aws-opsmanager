variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "aws_key_name_pcf" {}
variable "aws_key_name_ops" {}
variable "vpc_name" {}
variable "aws_region" {}
variable "mysql_username" {}
variable "mysql_password" {}
variable "bucket_prefix" {}

variable "aws_nat_ami" {
  default = {
    us-east-1 = "ami-4c9e4b24"
    us-west-1 = "ami-1d2b2958"
    us-west-2 = "ami-8b6912bb"
    ap-northeast-1 = "ami-49c29e48"
    ap-southeast-1 = "ami-d482da86"
    ap-southeast-2 = "ami-a164029b"
    eu-west-1 = "ami-5b60b02c"
    sa-east-1 = "ami-8b72db96"
  }
}

provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}



#Bucket Create if exist
resource "aws_s3_bucket" "OPS_MANAGER_S3_BUCKET" {
  bucket = "${var.bucket_prefix}-pcf-opsmgr"
    acl = "private"
}


resource "aws_s3_bucket" "ELASTIC_RUNTIME_S3_BUCKET" {
    bucket = "${var.bucket_prefix}-pcf-elastic-runtime"
    acl = "private"
}

#Create VPC

resource "aws_vpc" "pcf-vpc" {
    cidr_block = "10.0.0.0/16"
    tags {
    	 Name = "${var.vpc_name}"
    }
    enable_dns_hostnames = true
}

#Public subnet
resource "aws_subnet" "public-az1" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
	cidr_block = "10.0.0.0/24"
	availability_zone = "${var.aws_region}a"
	tags {
		Name = "public-az1"
	}
}

#Public subnet
resource "aws_subnet" "private-az1" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
	cidr_block = "10.0.16.0/20"
	availability_zone = "${var.aws_region}a"
	tags {
		Name = "private-az1"
	}
}



/*************************************
* RDS MYSQL
**************************************/


resource "aws_subnet" "rds-1" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
	cidr_block = "10.0.2.0/24"
	availability_zone = "${var.aws_region}a"
	tags {
		Name = "rds-1"
	}
}

resource "aws_subnet" "rds-2" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
	cidr_block = "10.0.3.0/24"
	availability_zone = "${var.aws_region}c"
	tags {
		Name = "rds-2"
	}
}

resource "aws_db_subnet_group" "PCF_RDSGroup" {
    name = "PCF_RDSGroup"
    description = "PCF_RDSGroup"
    subnet_ids = ["${aws_subnet.rds-1.id}","${aws_subnet.rds-2.id}"]
}

resource "aws_security_group" "MySQL" {
	name = "MySQL"
	description = "MySQL"
	vpc_id = "${aws_vpc.pcf-vpc.id}"

	ingress {
		from_port = 3306
		to_port = 3306
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]

	}

	tags {
		Name = "MySQL"
	}

}

resource "aws_db_instance" "pcf-bosh" {
    identifier = "pcf-bosh"
    allocated_storage = 100
    engine = "mysql"
    engine_version = "5.6.22"
    instance_class = "db.m3.large"
    username = "${var.mysql_username}"
    password = "${var.mysql_password}"
    db_subnet_group_name = "PCF_RDSGroup"
    parameter_group_name = "default.mysql5.6"
    name = "bosh"
    vpc_security_group_ids = ["${aws_security_group.MySQL.id}"]
    multi_az = true
    publicly_accessible = false
}






/* **********************************
* Security Groups
*
**************************************/

resource "aws_security_group" "OpsManager" {
	name = "OpsManager"
	description = "OpsManager"
	vpc_id = "${aws_vpc.pcf-vpc.id}"

	ingress {
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]

	}

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	tags {
		Name = "OpsManager"
	}

}


resource "aws_security_group" "pcfVMs" {
	name = "pcfVMs"
	description = "pcfVMs"
	vpc_id = "${aws_vpc.pcf-vpc.id}"


	ingress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["${aws_vpc.pcf-vpc.cidr_block}"]
	}


	tags {
		Name = "pcfVMs"
	}

}


resource "aws_security_group" "PCF_ELB_SecurityGroup" {
	name = "PCF_ELB_SecurityGroup"
	description = "PCF_ELB_SecurityGroup"
	vpc_id = "${aws_vpc.pcf-vpc.id}"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 4443
		to_port = 4443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}


	tags {
		Name = "PCF_ELB_SecurityGroup"
	}

}





resource "aws_security_group" "OutboundNAT" {
	name = "OutboundNAT"
	description = "OutboundNAT"
	vpc_id = "${aws_vpc.pcf-vpc.id}"

	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 443
		to_port = 443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	ingress {
		from_port = 4443
		to_port = 4443
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}


	tags {
		Name = "OutboundNAT"
	}

}




/* **********************************
* Instances
*
**************************************/


resource "aws_instance" "OpsManager" {
	ami = "${lookup(var.aws_pcf_opsmgr_ami, var.aws_region)}"
	instance_type = "m3.large"
	key_name = "${var.aws_key_name_ops}"
	subnet_id = "${aws_subnet.public-az1.id}"
	security_groups = ["${aws_security_group.OpsManager.id}"]
	associate_public_ip_address = true
	source_dest_check = false

	ebs_block_device {
		volume_type = "gp2"
		volume_size = "100"
		device_name = "/dev/sdb"
	}
	tags {
		Name = "OpsManager"
	}
}





/* **********************************
* Load Balancer
*
**************************************/

resource "aws_elb" "pcf-aws-lb" {
	name = "pcf-aws-lb"
	subnets = ["${aws_subnet.public-az1.id}"]
	security_groups = ["${aws_security_group.PCF_ELB_SecurityGroup.id}"]
	internal = false
	listener {
      instance_port = 80
      instance_protocol = "http"
      lb_port = 80
      lb_protocol = "http"
    }

    health_check {
      healthy_threshold = 10
      unhealthy_threshold = 2
      timeout = 5
      target = "TCP:80"
      interval = 10
  }



}



resource "aws_internet_gateway" "pcf-vpc-gw" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
}

/*
*
* NAT INSTANCES
*
*/
resource "aws_instance" "nat" {
  ami = "${lookup(var.aws_nat_ami, var.aws_region)}"
	instance_type = "t2.small"
	key_name = "${var.aws_key_name_ops}"
	security_groups = ["${aws_security_group.OutboundNAT.id}"]
	subnet_id = "${aws_subnet.public-az1.id}"
	associate_public_ip_address = false
	source_dest_check = false
	tags {
		Name = "nat"
	}
}



resource "aws_route_table" "public-az1-rt" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.pcf-vpc-gw.id}"
	}
}

resource "aws_route_table_association" "public-az1-rt-assoc" {
	subnet_id = "${aws_subnet.public-az1.id}"
	route_table_id = "${aws_route_table.public-az1-rt.id}"
}


resource "aws_route_table" "private-az1-rt" {
	vpc_id = "${aws_vpc.pcf-vpc.id}"

	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = "${aws_internet_gateway.pcf-vpc-gw.id}"
	}
}

resource "aws_route_table_association" "private-az1-rt-assoc" {
	subnet_id = "${aws_subnet.private-az1.id}"
	route_table_id = "${aws_route_table.private-az1-rt.id}"
}


############
# Outputs
############



output "OpsManager_Bucket" {
    value = "${aws_s3_bucket.OPS_MANAGER_S3_BUCKET.id}"
}


output "Elasticruntime_Bucket" {
    value = "${aws_s3_bucket.ELASTIC_RUNTIME_S3_BUCKET.id}"
}

output "Private_Avaibility_zone" {
    value = "${aws_subnet.private-az1.availability_zone}"
}

output "PCF_VPC_id" {
    value = "${aws_vpc.pcf-vpc.id}"
}

output "MySQL_Username" {
    value = "${aws_db_instance.pcf-bosh.username}"
}

output "MySQL_Database_Name" {
    value = "${aws_db_instance.pcf-bosh.name}"
}

output "MySQL_Host" {
    value = "${aws_db_instance.pcf-bosh.address}"
}


output "OpsManager-DNS" {
    value = "${aws_instance.OpsManager.public_dns}"
}
