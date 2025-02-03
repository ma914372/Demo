terraform {
  backend "s3" {
    bucket = "my-demo-bucket2025"
    key     = "terraform.tfstate"
    region  = "us-east-1"

  }
}
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

# --------------------- Subnets ---------------------
resource "aws_subnet" "kubernetes_subnet" {
  vpc_id                  = aws_vpc.demo_vpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "Kubernetes-Subnet"
    }
}

# --------------------- Internet Gateway ---------------------
resource "aws_internet_gateway" "demo_igw" {
  vpc_id = aws_vpc.demo_vpc.id

  tags = { Name = "Kubernetes-IGW" }
}

resource "aws_route_table" "demo_route_table" {
  vpc_id = aws_vpc.demo_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.demo_igw.id
  }

  tags = { Name = "Demo-RouteTable" }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.kubernetes_subnet.id
  route_table_id = aws_route_table.demo_route_table.id
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
resource "aws_route_table_association" "ansible_subnet_association" {
    subnet_id = aws_subnet.ansible_subnet.id
    route_table_id = aws_route_table.demo_route_table.id
}

# Security Group for Master Nodes
resource "aws_security_group" "kubernetes_master_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  # Allow SSH (22) from anywhere (if needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow K3s Server-Agent Communication (6444) from Master Node (by CIDR block)
  ingress {
    from_port   = 6444
    to_port     = 6444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from master node's subnet
  }

  # Allow K3s Server-Agent Communication (6444) from Master Node (by CIDR block)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from master node's subnet
  }

  # Allow K3s Server-Agent Communication (6444) from Master Node (by CIDR block)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from master node's subnet
  }

  # Allow Kubernetes API Server (6443) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from worker nodes' subnet
  }

  # Allow Kubelet API (10250) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from worker nodes' subnet
  }

  # Allow K3s Server-Agent Communication (9345) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from worker nodes' subnet
  }

  # Allow Flannel VXLAN (8472) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from worker nodes' subnet
  }
  # Allow etcd Cluster Communication (2379-2380) from Master Node (by CIDR block)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Allow Flannel Data Plane (8285) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from worker nodes' subnet
  }

  # Allow NodePort Communication (30000-32767) from Worker Nodes (by CIDR block)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from worker nodes' subnet
  }

  # Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Kubernetes-Master-SG" }
}

# Security Group for Worker Nodes
resource "aws_security_group" "kubernetes_worker_sg" {
  vpc_id = aws_vpc.demo_vpc.id

  # Allow SSH (22) from anywhere (if needed)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow inbound traffic on port 80 (HTTP) and 443 (HTTPS)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere (Internet)
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from anywhere (Internet)
  }

  # Allow communication to the Kubernetes API Server (6443) from Master Node (by CIDR block)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }
  # Allow K3s Server-Agent Communication (6444) from Master Node (by CIDR block)
  ingress {
    from_port   = 6444
    to_port     = 6444
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from master node's subnet
  }

  # Allow Kubelet Communication (10250) from Master Node (by CIDR block)
  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Allow K3s Server-Agent Communication (9345) from Master Node (by CIDR block)
  ingress {
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Allow Flannel VXLAN (8472) from Master Node (by CIDR block)
  ingress {
    from_port   = 8472
    to_port     = 8472
    protocol    = "udp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Allow Flannel Data Plane (8285) from Master Node (by CIDR block)
  ingress {
    from_port   = 8285
    to_port     = 8285
    protocol    = "udp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Allow NodePort Communication (30000-32767) from Master Node (by CIDR block)
  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from master node's subnet
  }

  # Allow etcd Cluster Communication (2379-2380) from Master Node (by CIDR block)
  ingress {
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.kubernetes_subnet.cidr_block]  # Allow from master node's subnet
  }

  # Outbound rule to allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Kubernetes-Worker-SG" }
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
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.my-key
    subnet_id = aws_subnet.kubernetes_subnet.id
    vpc_security_group_ids = [aws_security_group.kubernetes_master_sg.id]
    tags = {
        Name = "Kubernetes-Master-Node"
    }
}

resource "aws_instance" "kubernetes_worker_nodes" {
    count = 2
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.my-key
    subnet_id     = aws_subnet.kubernetes_subnet.id
    vpc_security_group_ids = [aws_security_group.kubernetes_worker_sg.id]
    tags = {
        Name = "Kubernetes-Worker-Node-${count.index}"
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





   

