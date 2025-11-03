# Configure AWS Provider 
provider "aws" {
}

# 1. Create VPC with IPv4 CIDR 10.0.0.0/24
resource "aws_vpc" "bens_vpc" {
  cidr_block = "10.0.0.0/24"
  enable_dns_hostnames = true
  tags = {
    Name = "Bens-Lab-AAP26-vpc"
  }
}

# 2. Create Subnet 10.0.0.0/25
resource "aws_subnet" "bens_subnet" {
  vpc_id            = aws_vpc.bens_vpc.id
  cidr_block        = "10.0.0.0/25"
  availability_zone = "us-east-2a"  # Change if needed
  tags = {
    Name = "Bens-Lab-AAP26"
  }
}

# 3. Request quota increase for Elastic IPs
resource "aws_servicequotas_service_quota" "eip_increase" {
  quota_code   = "L-0263D0A3"       # Fixed quota code for VPC Elastic IPs
  service_code = "ec2"              # EC2 service code
  value        = 25                 # Requested new quota value
}

data "aws_servicequotas_service_quota" "check_eip" {
  quota_code   = "L-0263D0A3"
  service_code = "ec2"
}

output "current_eip_quota" {
  value = data.aws_servicequotas_service_quota.check_eip.value
}

# 4. Create Internet Gateway
resource "aws_internet_gateway" "bens_igw" {
  vpc_id = aws_vpc.bens_vpc.id
  tags = {
    Name = "Bens-Lab-AAP26"
  }
}

# 5. Create Route Table
resource "aws_route_table" "bens_rt" {
  vpc_id = aws_vpc.bens_vpc.id
  tags = {
    Name = "Bens-Lab-AAP26"
  }
}

# 6. Add default route to Internet Gateway
resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.bens_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.bens_igw.id
}

# 7. Associate Subnet with Route Table
resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.bens_subnet.id
  route_table_id = aws_route_table.bens_rt.id
}

# 8. Build Security Group for my Lab
resource "aws_security_group" "ben_lab_sg" {
  name        = "ben-lab-sg"
  description = "Ben Security group for lab"
  vpc_id      = aws_vpc.bens_vpc.id  # Reference to the VPC created earlier

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP/HTTPS access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL access (standard port)
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Receptor access
  ingress {
    from_port   = 27199
    to_port     = 27199
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS Gateway access
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # PostgreSQL access (alternate port)
  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redis access
  ingress {
    from_port   = 16379
    to_port     = 16379
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # gRPC access
  ingress {
    from_port   = 50051
    to_port     = 50051
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic (default behavior)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bens-Lab-AAP26"
  }
}

data "aws_ami" "rhelami" {
  most_recent = true
  owners      = ["309956199498"]  # Official Red Hat account
  filter {
    name   = "name"
    values = ["${var.lookup_map[var.rhel_version]}*HVM*-*Access2*"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "aap26vms" {
  count                       = var.number_of_instances
  ami                         = data.aws_ami.rhelami.id
  instance_type               = "t2.xlarge"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.bens_subnet.id
  vpc_security_group_ids      = [aws_security_group.ben_lab_sg.id]
  key_name                    = "ben-lab-key-pair"

  # #Root volume configuration
  root_block_device {
    volume_size = 200    # 200 GiB
    volume_type = "gp3"
    iops        = 3000   # 3000 IOPS
    encrypted   = false  # Explicitly disable encryption
  }

  tags = {
    owner             = "bforrester"
    env               = "lab"
    operating_system  = var.rhel_version
    usage             = "aap26 lab builds"
  }
}
