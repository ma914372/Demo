provider "aws" {
    region = "${var.region}"
}

resource "aws_vpc" "demo_vpc" {
    cidr_block = "${var.vpc_cidr}"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = true
    tags = {
        Name = "Demo_kubernetes-VPC"
    }
}

resource "aws_subnet" "kubernetes_subnet_a" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "${var.subnet_cidr_kubernetes_a}"
  availability_zone       =  "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "Kuberenetes-Subnet-A"
  }
}
resource "aws_subnet" "kubernetes_subnet_b" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "${var.subnet_cidr_kubernetes_b}"
  availability_zone       =  "us-east-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "Kuberenetes-Subnet-B"
  }
}

resource "aws_subnet" "ansible_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "${var.subnet_cidr_ansible}"
  availability_zone       =  "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Ansible-Subnet"
  }
}

resource "aws_internet_gateway" "demo_igw" {
    vpc_id = aws_vpc.demo_vpc.id
    tags = {
        Name = "Kubernetes_IGW"
    }
}

resource "aws_route_table" "demo_route_table" {
    vpc_id = aws_vpc.demo_vpc.id
    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.demo_igw.id
    }
    tags = {
    Name = "Demo-RouteTable"
  }
}

resource "aws_route_table_association" "kubernetes_subnet_association_a" {
    subnet_id = aws_subnet.kubernetes_subnet_a.id
    route_table_id = aws_route_table.demo_route_table.id

}
resource "aws_route_table_association" "kubernetes_subnet_association_b" {
    subnet_id = aws_subnet.kubernetes_subnet_b.id
    route_table_id = aws_route_table.demo_route_table.id
    
}

resource "aws_route_table_association" "ansible_subnet_association" {
    subnet_id = aws_subnet.ansible_subnet.id
    route_table_id = aws_route_table.demo_route_table.id
}

resource "aws_security_group" "kubernetes_sg" {
    vpc_id = aws_vpc.demo_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 6443
        to_port = 6443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Kubernetes-SG"
    }
}

resource "aws_security_group" "ansible_sg" {
    vpc_id = aws_vpc.demo_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 6443
        to_port = 6443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "Ansible-SG"
    }
}
resource "aws_instance" "kubernetes_master" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.my-key
  subnet_id     = aws_subnet.kubernetes_subnet_a.id
  security_groups = [
    aws_security_group.kubernetes_sg.name
  ]
  tags = {
    Name = "Kubernetes-Master-Node"
  }
}

resource "aws_instance" "kubernetes_worker_nodes" {
    count = 2
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.my-key
    subnet_id     = element([aws_subnet.kubernetes_subnet_a.id, aws_subnet.kubernetes_subnet_b.id], count.index % 2)
    security_groups = [aws_security_group.kubernetes_sg.name]
    tags = {
        Name = "Kubernetes-Worker-Node-${count.index}"
    }
}
resource "aws_elb" "kubernetes_elb" {
  name               = "kubernetes-master-elb"
  availability_zones = [aws_subnet.kubernetes_subnet_a.availability_zone, aws_subnet.kubernetes_subnet_b.availability_zone]
  security_groups    = [aws_security_group.kubernetes_sg.id]
  subnets            = [aws_subnet.kubernetes_subnet_a.id, aws_subnet.kubernetes_subnet_b.id]

  listener {
    instance_port     = 6443
    instance_protocol = "TCP"
    lb_port           = 6443
    lb_protocol       = "TCP"
  }

  health_check {
    target              = "TCP:6443"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  instances = [aws_instance.kubernetes_master.id]

  tags = {
    Name = "Kubernetes-ELB"
  }
}

resource "aws_instance" "ansible_node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.my-key
  subnet_id     = aws_subnet.ansible_subnet.id
  security_groups = [aws_security_group.ansible_sg.name]
  tags = {
    Name = "Ansible-Control-Node"
  }
}







   

