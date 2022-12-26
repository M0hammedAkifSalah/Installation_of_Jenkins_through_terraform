provider "aws" {
  region = "ap-south-1"
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_availability_zones" "available" {}

resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "Default subnet for ap-south-1"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    
  }

  ingress {
    description      = "TLS from VPC"
    from_port        = 8000
    to_port          = 8000
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.main.cidr_block]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_tls"
  }
}

resource "aws_instance" "jenkins_server" {
  ami           = "ami-07ffb2f4d65357b42"
  instance_type = "t2.micro"
  subnet_id = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [ aws_security_group.allow_tls.id ]
  key_name = "jenkinskey"
  tags = {
    "Name" = "Jenkins_Server"
  }
}

resource "null_resource" "name" {

    connection {

      type = "ssh"
      user = "ubuntu"
      private_key = file("~/Downloads/jenkinskey.pem")
      host = aws_instance.jenkins_server.public_ip
    }
    
  


provisioner "file" {
    source = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
}

provisioner "remote-exec" {
    inline = [
        "sudo chmod +x /tmp/install_jenkins.sh",
        "sh /tmp/install_jenkins.sh" 

    ]

}

depends_on = [
    aws_instance.jenkins_server
]

}
