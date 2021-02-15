provider "aws" {
  region = "us-east-1"
  profile = "default"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
        Name = "my-vpc"
    }
}

resource "aws_subnet" "my-subnet-public-1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.16.10.0/24"
  availability_zone = "us-east-1a"
  tags = {
        Name = "my-public-subent"
    }
}

resource "aws_subnet" "my-subnet-public-2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "172.16.20.0/24"
  availability_zone = "us-east-1b"
  tags = {
        Name = "my-public-subent"
    }
}
resource "aws_internet_gateway" "my-igw" {
   vpc_id     = aws_vpc.my_vpc.id
     tags = {
        Name = "my-igw"
    }
}
resource "aws_route_table" "my-public-crt" {
    vpc_id     = aws_vpc.my_vpc.id
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.my-igw.id 
    }
    
     tags = {
        Name = "my-public-crt"
    }
}

resource "aws_route_table_association" "my-crta-public-subnet-1"{
    subnet_id = aws_subnet.my-subnet-public-1.id
    route_table_id = aws_route_table.my-public-crt.id
}

resource "aws_route_table_association" "my-crta-public-subnet-2"{
    subnet_id = aws_subnet.my-subnet-public-2.id
    route_table_id = aws_route_table.my-public-crt.id
}
resource "aws_security_group" "my-sg" {
   vpc_id     = aws_vpc.my_vpc.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["0.0.0.0/0"]
    }
     ingress {
        from_port = 3306
        to_port = 3306
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = ["172.16.0.0/16"]
    }
    //If you do not add this rule, you can not reach the NGIX  
    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "my-sg"
    }
}

resource "aws_iam_role" "my_iam_role" {
  name = "my_iam_role"

  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Action": "sts:AssumeRole",
          "Principal": {
            "Service": "ec2.amazonaws.com"
          },
          "Effect": "Allow",
          "Sid": ""
        }
      ]
    }
EOF
}
resource "aws_iam_role_policy_attachment" "ssm_policy_attachment" {
  role       = aws_iam_role.my_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.my_iam_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_instance_profile" "my_profile" {
  name  = "my_profile"
  role = aws_iam_role.my_iam_role.name
}

resource "aws_key_pair" "my_key" {
  key_name   = "my_key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC+PwWlmY5bS9jbQPM5kfp5TrpxYNOjOhlLZQ2WgSYctap9eSmy0dm4jD8J1pF+DGfHMBjP/b0aV7VHFsbwaakbxftAq+Hptt90Y4/t3jp/GRUiqnBcKT9KI0aYefmqTRI1JOLT75fPeUihDOIvIqVzJ2KlTlBMp5cQk9q+6VWl4NOlO4oXvRes0Qd+QXugoal7foumvf4R9DlvU3xPlbXk6zbHLK8PJwuBjFoEIou+ljs15NXSOfFeKeTuGPwsZBb5YYcqQhhs0Dj8225VdxTIVojzV9wMTCA27+Un1DqoXD/l8bW6Vh5FOJN24bjVhL1Rd4JEJOxnCDPjGJFgxE6R root@ip-172-16-10-174"
}


resource "aws_instance" "web-server" {

    ami = "ami-047a51fa27710816e"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my-subnet-public-1.id
    vpc_security_group_ids =  ["${aws_security_group.my-sg.id}"]
    iam_instance_profile = aws_iam_instance_profile.my_profile.name
    private_ip = "172.16.10.15"
    key_name  = aws_key_pair.my_key.id
    user_data = file("web_configure")
    tags = {
        Name = "my-web-server"
    }
       
    }

resource "aws_instance" "my-monitor-server" {

    ami = "ami-047a51fa27710816e"
    instance_type = "t2.micro"
    subnet_id = aws_subnet.my-subnet-public-1.id
    vpc_security_group_ids =  ["${aws_security_group.my-sg.id}"]
    iam_instance_profile = aws_iam_instance_profile.my_profile.name
    key_name  = aws_key_pair.my_key.id
    user_data = file("app_configure")
    tags = {
        Name = "my-monitor-server"
    }
       
    }

resource "aws_eip" "web-ip" {
  instance = aws_instance.web-server.id
  vpc      = true
  tags = {
        Name = "my-web-server-ip"
    } 

}

resource "aws_eip" "monitor-ip" {
  instance = aws_instance.my-monitor-server.id
  vpc      = true
  tags = {
        Name = "my-monitor-server-ip"
    } 

}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [aws_subnet.my-subnet-public-1.id,aws_subnet.my-subnet-public-2.id]

  tags = {
    Name = "My DB subnet group"
  }
}
resource "aws_db_instance" "default" {
  db_subnet_group_name = aws_db_subnet_group.default.id
  vpc_security_group_ids = ["${aws_security_group.my-sg.id}"]
  allocated_storage    = 20
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t2.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"

  tags = {
        Name = "my-mysql-db"
    } 
}
resource "aws_s3_bucket" "s3-my-log-backup" {
  bucket = "s3-my-log-backup"
  acl    = "private"

  tags = {
    Name        = "s3-my-log-backup"
    Environment = "my"
  }
}
