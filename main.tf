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
resource "aws_subnet" "kubernetes_subnet_c" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "${var.subnet_cidr_kubernetes_c}"
  availability_zone       =  "us-east-1c"
  map_public_ip_on_launch = true
  tags = {
    Name = "Kuberenetes-Subnet-C"
  }
}

resource "aws_subnet" "ansible_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = "${var.subnet_cidr_ansible}"
  availability_zone       =  "us-east-1b"
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
resource "aws_route_table_association" "kubernetes_subnet_association_c" {
    subnet_id = aws_subnet.kubernetes_subnet_c.id
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
    count = 3
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.my-key
    subnet_id = element([aws_subnet.kubernetes_subnet_a.id, aws_subnet.kubernetes_subnet_b.id, aws_subnet.kubernetes_subnet_c.id], count.index)
    vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
    tags = {
        Name = "Kubernetes-Master-Node-${count.index}"
    }
}

resource "aws_instance" "kubernetes_worker_nodes" {
    count = 2
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.my-key
    subnet_id     = element([aws_subnet.kubernetes_subnet_b.id, aws_subnet.kubernetes_subnet_c.id], count.index % 2)
    vpc_security_group_ids = [aws_security_group.kubernetes_sg.id]
    tags = {
        Name = "Kubernetes-Worker-Node-${count.index}"
    }
}
resource "aws_lb" "kubernetes_alb" {
  name               = "kubernetes-master-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.kubernetes_sg.id]
  subnets            = [
    aws_subnet.kubernetes_subnet_a.id,
    aws_subnet.kubernetes_subnet_b.id,
    aws_subnet.kubernetes_subnet_c.id
  ]
  tags = {
    Name = "Kubernetes-ALB"
  }
}

# Define a Target Group for the ALB
resource "aws_lb_target_group" "kubernetes_master_tg" {
  name        = "kubernetes-master-target-group"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.demo_vpc.id
  target_type = "instance"

  health_check {
    protocol            = "TCP"
    port                = "6443"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Attach the Master Nodes to the Target Group
resource "aws_lb_target_group_attachment" "kubernetes_master_tg_attachment" {
  count            = 2
  target_group_arn = aws_lb_target_group.kubernetes_master_tg.arn
  target_id        = aws_instance.kubernetes_master[count.index].id
  port             = 6443
}

# Configure the ALB Listener
resource "aws_lb_listener" "kubernetes_master_listener" {
  load_balancer_arn = aws_lb.kubernetes_alb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kubernetes_master_tg.arn
  }
}

resource "aws_instance" "ansible_node" {
  ami           = var.ami_id
  instance_type = var.instance_type
  key_name      = var.my-key
  subnet_id     = aws_subnet.ansible_subnet.id
  vpc_security_group_ids = [aws_security_group.ansible_sg.id]
  tags = {
    Name = "Ansible-Control-Node"
  }
}







   

